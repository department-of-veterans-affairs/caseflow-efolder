class ManifestFetcher
  include ActiveModel::Model

  attr_accessor :manifest_source

  EXCEPTIONS = [VBMS::ClientError, VVA::ClientError].freeze

  # We've found for some veteran eFolders, VVA returns the same document multiple times. We filter those out here.
  def remove_duplicates(documents)
    list_of_ids = {}

    documents.select do |doc|
      if !list_of_ids[doc.document_id]
        list_of_ids[doc.document_id] = true
        true
      else
        false
      end
    end
  end

  def process
    documents = remove_duplicates(manifest_source.service.v2_fetch_documents_for(manifest_source))

    DocumentCreator.new(manifest_source: manifest_source, external_documents: documents).create
    manifest_source.update!(status: :success, fetched_at: Time.zone.now)
    documents
  rescue *EXCEPTIONS => e
    manifest_source.update!(status: :failed)
    ExceptionLogger.capture(e)
    []
  end
end
