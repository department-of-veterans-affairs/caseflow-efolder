class V2::PackageFilesJob < ActiveJob::Base
  queue_as :default

  def perform(manifest)
    manifest.sources.each { |source| V2::SaveFilesInS3Job.perform_now(source) }
    manifest.update(fetched_files_status: :finished, fetched_files_at: Time.zone.now)
  # TODO: package files
  # Catch StandardError in case there is an error to avoid files downloads being stuck in pending state
  rescue StandardError => e
    manifest.update!(fetched_files_status: :failed)
    raise e
  end

  def max_attempts
    1
  end
end
