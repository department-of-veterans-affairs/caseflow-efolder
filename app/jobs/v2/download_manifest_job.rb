class V2::DownloadManifestJob < ActiveJob::Base
  queue_as :default

  def perform(manifest_source)
    documents = ManifestFetcher.new(manifest_source: manifest_source).process
    return if documents.blank?
    DocumentCreator.new(manifest_source: manifest_source, external_documents: documents).create
  # Start downloading files if it is not eX user
  # V2::SaveFilesInS3Job.perform_later(manifest_source)
  # Catch StandardError in case there is an error to avoid manifests being stuck in pending state
  rescue StandardError => e
    manifest_source.update!(status: :failed)
    raise e
  end

  def max_attempts
    1
  end
end
