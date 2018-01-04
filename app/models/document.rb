# frozen_string_literal: true
class Document < ActiveRecord::Base
  include Caseflow::DocumentTypes

  belongs_to :download

  AVERAGE_DOWNLOAD_RATE_LIMIT = 100
  AVERAGE_DOWNLOAD_RATE_CACHE_EXPIRATION = 30.seconds
  AVERAGE_DOWNLOAD_RATE_CACHE_KEY = "historical-average-download-rate".freeze
  MAXIMUM_FILENAME_LENGTH = 100

  enum download_status: { pending: 0, success: 1, failed: 2 }

  after_initialize { |document| document.vbms_filename ||= "" }

  # It is expected that some of the documents may have a MIME type of "application/octet-stream".
  # However, there is not a guarantee that all documents of this type can be opened as PDFs.
  # The "application/octet-stream" MIME type could represent arbitrary data, mislabeled PDFs, etc.
  # and there is no guarantee on file format without investigating the individual document.
  # Convert mime type to "application/pdf" if it is a binary file
  # then PDFkit will check if PDF is valid
  before_create :adjust_mime_type

  def self.ordered_by_completed_at
    where.not(completed_at: nil).order(completed_at: :desc)
  end

  def filename
    Zaru.sanitize! "#{cropped_type_name}-#{filename_date}-#{filename_doc_id}.#{preferred_extension}"
  end

  def path
    @path ||= File.join(download.download_dir, id.to_s)
  end

  def s3_stored_file_mime_type
    @s3_stored_file_mime_type || mime_type
  end
  attr_writer :s3_stored_file_mime_type

  def fetch_content!(save_document_metadata:)
    return {
      content: fetcher.content(save_document_metadata: save_document_metadata),
      error_kind: nil
    }
  rescue VBMS::ClientError => e
    update_with_error "VBMS::ClientError::#{e.message}\n#{e.backtrace.join("\n")}"
    return { content: nil, error_kind: :vbms_error }
  rescue VVA::ClientError => e
    update_with_error "VVA::ClientError::#{e.message}\n#{e.backtrace.join("\n")}"
    return { content: nil, error_kind: :vva_error }
  rescue ActiveRecord::StaleObjectError
    Rails.logger.info "Duplicate download detected. Document ID: #{id}"
    return { content: nil, error_kind: :caseflow_efolder_error }
  end

  # Since Windows has the maximum length for a path, we crop type_name if the filename is longer than set maximum (issue #371)
  def cropped_type_name
    over_limit = (Zaru.sanitize! "#{type_name}-#{filename_date}-#{filename_doc_id}.#{preferred_extension}").size - MAXIMUM_FILENAME_LENGTH
    end_index = (over_limit <= 0) ? -1 : -1 - over_limit
    type_name[0..end_index]
  end

  def filename_date
    received_at ? received_at.to_formatted_s(:filename) : "00000000"
  end

  def from_vva?
    downloaded_from == "VVA"
  end

  def from_vbms?
    downloaded_from == "VBMS"
  end

  def can_be_access_by?(user)
    user && download.user.css_id == user.css_id
  end

  def filename_doc_id
    (document_id || "").gsub(/[}{]/, "")
  end

  def s3_filename
    "#{document_id}.#{preferred_extension}"
  end

  def download_status_icon
    {
      "success" => :success,
      "failed" => :failed
    }[download_status]
  end

  def type_name
    type_description || TYPES[type_id.to_i] || vbms_filename
  end

  def fetcher
    @fetcher ||= Fetcher.new(document: self, external_service: external_service)
  end

  def save_locally(content)
    if preferred_extension == "pdf"
      PdfService.write(path, content, pdf_attributes)
    else
      File.open(path, "wb") do |f|
        f.write(content)
      end
    end
  end

  def pdf_attributes
    {
      "Document Type" => type_name,
      "Receipt Date" => received_at ? received_at.iso8601 : "",
      "Document ID" => document_id
    }
  end

  def unique_filename(index)
    "#{format('%04d', index + 1)}0-#{filename}"
  end

  def self.historical_average_download_rate
    time_floor = TimeUtil.floor(AVERAGE_DOWNLOAD_RATE_CACHE_EXPIRATION)
    cache = Rails.cache.read(AVERAGE_DOWNLOAD_RATE_CACHE_KEY)

    return cache[:value] if cache && cache[:updated_at] == time_floor

    calculate_and_save_historical_average_download_rate!
  end

  def preferred_extension
    mime = MIME::Types[s3_stored_file_mime_type].first
    mime ? mime.preferred_extension : ""
  end

  class << self
    def calculate_and_save_historical_average_download_rate!
      value = calculate_historical_average_download_rate
      obj = {
        updated_at: TimeUtil.floor(AVERAGE_DOWNLOAD_RATE_CACHE_EXPIRATION),
        value: value
      }

      Rails.cache.write(AVERAGE_DOWNLOAD_RATE_CACHE_KEY, obj)
      value
    end

    # This calculates the historical average rate at which files are downloaded
    # This takes the time spend downloading all files over the past hour and
    # divides by the total number of files in that period
    def calculate_historical_average_download_rate
      documents = ordered_by_completed_at.limit(AVERAGE_DOWNLOAD_RATE_LIMIT).all
      calculate_average_download_rate(documents)
    end

    def calculate_average_download_rate(documents)
      return nil if documents.empty?
      count = documents.count

      total_time = documents.inject(0) do |total, document|
        total + (document.completed_at - document.started_at)
      end

      (total_time / count).round(2)
    end
  end

  private

  def update_with_error(error)
    update_attributes!(
      download_status: :failed,
      error_message: error
    )
  end

  def external_service
    from_vva? ? VVAService : VBMSService
  end

  def adjust_mime_type
    self.mime_type = "application/pdf" if mime_type == "application/octet-stream"
  end
end
