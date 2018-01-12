class Record < ActiveRecord::Base
  belongs_to :manifest_source

  validates :manifest_source, :version_id, :series_id, presence: true
  validates :version_id, :series_id, uniqueness: true

  enum status: {
    initialized: 0,
    pending: 1,
    success: 2,
    failed: 3
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

  def preferred_extension
    mime ? mime.preferred_extension : ""
  end

  def accessible_by?(user)
    user && manifest.downloaded_by?(user)
  end

  def self.create_from_external_document(manifest_source, document)
    find_or_initialize_by(manifest_source: manifest_source, series_id: document.series_id).tap do |t|
      t.assign_attributes(
        type_id: document.type_id,
        version_id: document.document_id,
        version: document.version.to_i,
        type_description: document.type_description,
        mime_type: document.mime_type,
        received_at: document.received_at,
        jro: document.jro,
        source: document.source
      )
      t.save!
    end
  end

  private

  def fetcher
    @fetcher ||= RecordFetcher.new(record: self)
  end

  def mime
    MIME::Types[conversion_success? ? ImageConverterService.converted_mime_type(mime_type) : mime_type].first
  end

  def adjust_mime_type
    self.mime_type = "application/pdf" if mime_type == "application/octet-stream"
  end
end
