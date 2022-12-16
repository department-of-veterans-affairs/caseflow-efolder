class V2::DownloadManifestJob < ApplicationJob
  queue_as :high_priority

  def perform(manifest_source, user = nil)
    return if manifest_source.current?

    RequestStore.store[:current_user] = user if user
    Raven.extra_context(manifest_source: manifest_source.id)

    documents = ManifestFetcher.new(manifest_source: manifest_source).process
    CaseflowLogger.log("DownloadManifestJob", user: current_user.inspect, file_number: manifest_source.manifest.file_number, documents_fetched_count: documents.count, documents_fetched_ids: documents.map(&:id), manifest_zipfile_size: manifest_source.manifest.zipfile_size)

    V2::SaveFilesInS3Job.perform_later(manifest_source) if documents.present? && !ApplicationController.helpers.ui_user?
  rescue StandardError => error
    manifest_source.update!(status: :failed)
    Rails.logger.error "DownloadManifestJob encountered error #{error.class.name} when fetching manifest for appeal #{manifest_source.manifest.file_number}"
    raise error
  end

  def max_attempts
    1
  end

  private

  def current_user
    RequestStore[:current_user]
  end
end
