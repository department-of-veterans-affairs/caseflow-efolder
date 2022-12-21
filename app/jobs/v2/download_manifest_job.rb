class V2::DownloadManifestJob < ApplicationJob
  queue_as :high_priority

  def perform(manifest_source, user = nil)
    return if manifest_source.current?

    RequestStore.store[:current_user] = user if user
    Raven.extra_context(manifest_source: manifest_source.id)

    documents = ManifestFetcher.new(manifest_source: manifest_source).process

    V2::SaveFilesInS3Job.perform_later(manifest_source) if documents.present? && !ApplicationController.helpers.ui_user?
  rescue StandardError => error
    manifest_source.update!(status: :failed)
    raise error
  end

  def max_attempts
    1
  end
end
