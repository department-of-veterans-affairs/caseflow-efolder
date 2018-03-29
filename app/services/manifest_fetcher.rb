class ManifestFetcher
  include ActiveModel::Model

  attr_accessor :manifest_source

  EXCEPTIONS = [VBMS::ClientError, VVA::ClientError].freeze

  # VVA has a bug where they return these ids in multiple veteran's eFolders. This violates our unique constraint
  # and since documents should be unique to veterans, we have decided to filter out these documents.
  VVA_DUPLICATE_ID_LIST = %w[{F291C1BC-FCDE-4C58-8544-B4FCE2E59008}].freeze

  def process
    documents = manifest_source.service.v2_fetch_documents_for(manifest_source).reject do |document|
      VVA_DUPLICATE_ID_LIST.include?(document.document_id)
    end
    DocumentCreator.new(manifest_source: manifest_source, external_documents: documents).create
    manifest_source.update!(status: :success, fetched_at: Time.zone.now)
    documents
  rescue *EXCEPTIONS => e
    manifest_source.update!(status: :failed)
    ExceptionLogger.capture(e)
    []
  end
end
