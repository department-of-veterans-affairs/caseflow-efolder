class V2::PackageFilesJob < ActiveJob::Base
  queue_as :default

  SECONDS_TO_AUTO_UNLOCK = 43_200

  def perform(manifest)
    s = Redis::Semaphore.new("package_files_#{manifest.id}".to_s,
                             url: Rails.application.secrets.redis_url_sidekiq)

    s.lock(SECONDS_TO_AUTO_UNLOCK)

    return if manifest.recently_downloaded_files?

    ZipfileCreator.new(manifest: manifest).process
  # Catch StandardError in case there is an error to avoid files downloads being stuck in pending state
  rescue StandardError => e
    manifest.update!(fetched_files_status: :failed)
    raise e
  ensure
    s.unlock
  end

  def max_attempts
    1
  end
end
