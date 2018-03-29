class Record < ApplicationRecord
  include Caseflow::DocumentTypes

  belongs_to :manifest_source

  validates :manifest_source, :version_id, :series_id, presence: true

  enum status: {
    initialized: 0,
    success: 1,
    failed: 2
  }

  enum conversion_status: {
    not_converted: 0,
    conversion_success: 1,
    conversion_failed: 2
  }

  # It is expected that some of the documents may have a MIME type of "application/octet-stream".
  # However, there is not a guarantee that all documents of this type can be opened as PDFs.
  # The "application/octet-stream" MIME type could represent arbitrary data, mislabeled PDFs, etc.
  # and there is no guarantee on file format without investigating the individual document.
  # Convert mime type to "application/pdf" if it is a binary file
  # then PDFkit will check if PDF is valid
  before_create :adjust_mime_type

  delegate :manifest, :service, to: :manifest_source
  delegate :file_number, to: :manifest

  AVERAGE_DOWNLOAD_TIME_IN_SECONDS = 2

  MAXIMUM_FILENAME_LENGTH = 100

  def fetch!
    fetcher.process
  end

  # TODO: remove this method when implmenentation of VVA/VBMS service is changed towards v2 API
  def ssn
    file_number
  end

  # TODO: remove this method when implmenentation of VVA/VBMS service is changed towards v2 API
  def document_id
    version_id
  end

  def s3_filename
    "#{version_id}.#{preferred_extension}"
  end

  def filename
    Zaru.sanitize! "#{cropped_type_name}-#{filename_date}-#{filename_doc_id}.#{preferred_extension}"
  end

  def type_description
    super || TYPES[type_id.to_i]
  end

  def preferred_extension
    mime ? mime.preferred_extension : ""
  end

  def accessible_by?(user)
    user && manifest.downloaded_by?(user)
  end

  def self.create_from_external_document(manifest_source, document)
    create!(
      manifest_source: manifest_source,
      version_id: document.document_id,
      type_id: document.type_id,
      series_id: document.series_id,
      version: document.version.to_i,
      type_description: document.type_description,
      mime_type: document.mime_type,
      received_at: document.received_at,
      jro: document.jro,
      source: document.source
    )
  end

  private

  def fetcher
    @fetcher ||= RecordFetcher.new(record: self)
  end

  # Since Windows has the maximum length for a path, we crop type_name if the filename is longer than set maximum (issue #371)
  def cropped_type_name
    over_limit = (Zaru.sanitize! "#{type_description}-#{filename_date}-#{filename_doc_id}.#{preferred_extension}").size - MAXIMUM_FILENAME_LENGTH
    end_index = over_limit <= 0 ? -1 : -1 - over_limit
    type_description[0..end_index]
  end

  def filename_date
    received_at ? received_at.to_formatted_s(:filename) : "00000000"
  end

  def filename_doc_id
    (version_id || "").gsub(/[}{]/, "")
  end

  def mime
    MIME::Types[conversion_success? ? ImageConverterService.converted_mime_type(mime_type) : mime_type].first
  end

  def adjust_mime_type
    self.mime_type = "application/pdf" if mime_type == "application/octet-stream"
  end
end
