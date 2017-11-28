class V2::DownloadManifestJob < ActiveJob::Base
  queue_as :default

  around_perform :set_vbms_version

  def perform(service, manifest_source)
    documents = service.fetch_documents_for(manifest_source.manifest)
    DocumentCreator.new(manifest_source: manifest_source, external_documents: documents).create
  # TODO: make a parent class for these two errors
  rescue VBMS::ClientError, VVA::ClientError => e
    Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
    Raven.capture_exception(e)
  end

  private

  # Use VBMS efolder new API
  def set_vbms_version
    FeatureToggle.enable!(:vbms_efolder_service_v1)
    yield
    FeatureToggle.disable!(:vbms_efolder_service_v1)
  end

  def max_attempts
    1
  end
end
