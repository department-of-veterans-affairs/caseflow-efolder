class V2::PackageFilesJob < ApplicationJob
  queue_as :med_priority

  def perform(manifest)
    return if manifest.recently_downloaded_files?

    Raven.extra_context(manifest: manifest.id)

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
