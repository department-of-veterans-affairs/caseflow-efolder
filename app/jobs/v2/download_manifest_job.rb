class V2::DownloadManifestJob < ActiveJob::Base
  queue_as :high_priority

  def perform(manifest_source, ui_user)
    return if manifest_source.current?

    documents = ManifestFetcher.new(manifest_source: manifest_source).process

    V2::SaveFilesInS3Job.perform_later(manifest_source) if documents.present? && !ui_user
  rescue StandardError => e
    manifest_source.update!(status: :failed)
    raise e
  end

  def max_attempts
    1
  end
end
