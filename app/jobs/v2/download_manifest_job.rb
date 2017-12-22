class V2::DownloadManifestJob < ActiveJob::Base
  queue_as :default

  def perform(manifest_source)
    documents = ManifestFetcher.new(manifest_source: manifest_source).process
    return if documents.blank?
    DocumentCreator.new(manifest_source: manifest_source, external_documents: documents).create
    # start caching files in s3 when manifest is fetched succesfully
    V2::SaveFilesInS3Job.perform_later(manifest_source)
  end

  def max_attempts
    1
  end
end
