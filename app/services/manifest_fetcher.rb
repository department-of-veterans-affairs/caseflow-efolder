class ManifestFetcher
  include ActiveModel::Model

  attr_accessor :manifest_source

  EXCEPTIONS = [VBMS::ClientError, VVA::ClientError].freeze

  def process
    DocumentCreator.new(manifest_source: manifest_source, external_documents: documents).create
    manifest_source.update!(status: :success, fetched_at: Time.zone.now)
    documents
  rescue *EXCEPTIONS => e
    manifest_source.update!(status: :failed)
    ExceptionLogger.capture(e)
    []
  end

  def documents
    manifest_source.service.v2_fetch_documents_for(manifest_source.file_number)
  end
end
