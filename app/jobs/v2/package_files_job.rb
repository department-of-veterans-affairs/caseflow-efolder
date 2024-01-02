class V2::PackageFilesJob < ApplicationJob
  queue_as :med_priority

  def perform(manifest)
    return if manifest.recently_downloaded_files?

    Raven.extra_context(manifest: manifest.id)

    zipfile_size = ZipfileCreator.new(manifest: manifest).process
    manifest.update(
      zipfile_size: zipfile_size,
      fetched_files_status: :finished,
      fetched_files_at: Time.zone.now
    )
  # Catch StandardError in case there is an error to avoid files downloads being stuck in pending state
  rescue StandardError => error
    manifest.update!(fetched_files_status: :failed)
    raise error
  end

  def max_attempts
    1
  end
end
