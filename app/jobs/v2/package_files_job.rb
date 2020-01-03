class V2::PackageFilesJob < ActiveJob::Base
  queue_as :med_priority

  def perform(manifest)
    puts "start V2::PackageFilesJob"
    return if manifest.recently_downloaded_files?

    ZipfileCreator.new(manifest: manifest).process
  # Catch StandardError in case there is an error to avoid files downloads being stuck in pending state
  rescue StandardError => e
    manifest.update!(fetched_files_status: :failed)
    raise e
  end

  def max_attempts
    1
  end
end
