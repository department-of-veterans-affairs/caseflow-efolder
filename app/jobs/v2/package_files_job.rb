class V2::PackageFilesJob < ActiveJob::Base
  queue_as :default

  def perform(user_manifest)
    # TODO: keep calling fetch if status is pending and create zip file at the end
    user_manifest.records.each(&:fetch!)
    user_manifest.update(status: :finished, fetched_files_at: Time.zone.now)
  # Catch StandardError in case there is an error to avoid user manifests being stuck in pending state
  rescue StandardError => e
    user_manifest.update!(status: :failed)
    raise e
  end

  def max_attempts
    1
  end
end
