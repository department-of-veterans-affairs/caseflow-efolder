# frozen_string_literal: true

class ManifestFetcher
  include ActiveModel::Model

  attr_accessor :manifest_source

  # Catch StandardError in case there is an error to avoid manifests being stuck in pending state
  EXCEPTIONS = [VBMS::ClientError, VVA::ClientError, StandardError].freeze

  def process
    documents = manifest_source.service.fetch_documents_for(manifest_source.manifest)
    manifest_source.update(status: :success, fetched_at: Time.zone.now)
    documents
  rescue *EXCEPTIONS => e
    manifest_source.update(status: :failed)
    ExceptionLogger.capture(e)
    []
  end
end
