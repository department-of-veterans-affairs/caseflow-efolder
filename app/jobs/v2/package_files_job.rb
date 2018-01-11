class V2::PackageFilesJob < ActiveJob::Base
  queue_as :default

  def perform(files_download)
    # TODO: keep calling fetch if status is pending and create zip file at the end
    files_download.records.each(&:fetch!)
    files_download.update(status: :finished, fetched_files_at: Time.zone.now)
  # Catch StandardError in case there is an error to avoid user manifests being stuck in pending state
  rescue StandardError => e
    files_download.update!(status: :failed)
    raise e
  end

  def max_attempts
    1
  end
end
