class V2::DownloadManifestJob < ApplicationJob
  queue_as :high_priority

  def perform(manifest_source, user = nil)
    manifest_source.update(status: :pending)

    RequestStore.store[:current_user] = user if user
    Raven.extra_context(manifest_source: manifest_source.id)

    documents = ManifestFetcher.new(manifest_source: manifest_source).process

    log_info(manifest_source.manifest.file_number, documents, manifest_source.manifest.zipfile_size)

    #V2::SaveFilesInS3Job.perform_later(manifest_source) if documents.present? && !ApplicationController.helpers.ui_user?
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

  def log_info(file_number, docs, zipfile_size)
    Rails.logger.info log_message(file_number, docs, zipfile_size)
  end

  def log_message(file_number, docs, zipfile_size)
    "DownloadManifestJob - " \
    "User Inspect: (#{current_user.inspect})" \
    "File Number: (#{file_number}) - " \
    "Documents Fetched Count: #{docs.count} - " \
    "Documents Fetched IDs: #{docs.map(&:id)}" \
    "Manifest Zipfile Size: #{zipfile_size} - "
  end
end
