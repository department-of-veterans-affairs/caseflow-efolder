class V2::DownloadManifestJob < ActiveJob::Base
  queue_as :high_priority

  def perform(manifest_source, user = nil)
    puts "start V2::DownloadManifestJob for #{manifest_source.name}"
    return if manifest_source.current?
    RequestStore.store[:current_user] = user if user

    puts "ManifestFetcher.new.process"
    documents = ManifestFetcher.new(manifest_source: manifest_source).process

    puts "found documents #{documents.length}"

    V2::SaveFilesInS3Job.perform_later(manifest_source) if documents.present? && !ApplicationController.helpers.ui_user?
  rescue StandardError => e
    manifest_source.update!(status: :failed)
    puts "Marked #{manifest_source.name} as status=failed, re-raising #{e}"
    raise e
  end

  def max_attempts
    1
  end
end
