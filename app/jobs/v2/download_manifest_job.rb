class V2::DownloadManifestJob < ActiveJob::Base
  queue_as :default

  around_perform :set_vbms_version

  def perform(manifest_source)
    documents = ManifestFetcher.new(manifest_source: manifest_source).process
    return if documents.blank?
    DocumentCreator.new(manifest_source: manifest_source, external_documents: documents).create
  end

  private

  # Use VBMS efolder new API - remove it when switched to the new API
  def set_vbms_version
    FeatureToggle.enable!(:vbms_efolder_service_v1)
    yield
    FeatureToggle.disable!(:vbms_efolder_service_v1)
  end

  def max_attempts
    1
  end
end
