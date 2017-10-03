class DownloadManifestJob < ActiveJob::Base
  queue_as :default

  # pass graceful=true if the job should continue to obtain doc manifests from other services after a failure
  def perform(download, graceful=false)
    external_documents = []
    has_error = false

    # fetch vbms docs
    begin
      external_documents += VBMSService.fetch_documents_for(download)
      download.update_attributes!(manifest_vbms_fetched_at: Time.zone.now)
    rescue VBMS::ClientError => e
      has_error = capture_error(e, download, :vbms_connection_error)
      return if !graceful
    end

    # fetch vva docs
    if FeatureToggle.enabled?(:vva_service, user: download.user)
      begin
          external_documents += VVAService.fetch_documents_for(download)
          download.update_attributes!(manifest_vva_fetched_at: Time.zone.now)
      rescue VVA::ClientError => e
        has_error  = capture_error(e, download, :vva_connection_error)
        return if !graceful
      end
    end

    if external_documents.empty?
      download.update_attributes!(status: :no_documents)
      return
    end

    download_documents = DownloadDocuments.new(
      download: download,
      external_documents: external_documents
    )
    download_documents.create_documents
    download.update_attributes!(status: :pending_confirmation) if !has_error
  end

  def max_attempts
    1
  end

  def capture_error(e, download, status)
    Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
    Raven.capture_exception(e)
    download.update_attributes!(status: status)
  end
end
