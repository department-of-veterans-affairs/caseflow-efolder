class V2::DownloadManifestJob < ActiveJob::Base
  queue_as :default

  SECONDS_TO_AUTO_UNLOCK = 180

  def perform(manifest_source, ui_user)
    s = Redis::Semaphore.new("download_manifest_source_#{manifest_source.id}".to_s,
                             url: Rails.application.secrets.redis_url_sidekiq)

    s.lock(SECONDS_TO_AUTO_UNLOCK)
    return if manifest_source.current?

    documents = ManifestFetcher.new(manifest_source: manifest_source).process

    V2::SaveFilesInS3Job.perform_later(manifest_source) if documents.present? && !ui_user
  rescue StandardError => e
    manifest_source.update!(status: :failed)
    raise e
  ensure
    s.unlock
  end

  def max_attempts
    1
  end
end
