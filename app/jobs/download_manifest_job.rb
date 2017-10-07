class DownloadManifestJob < ActiveJob::Base
  queue_as :default

  # pass graceful=true if the job should continue to obtain doc manifests from other services after a failure
  def perform(download, graceful = false)
    external_documents = []
    has_error = false

    # fetch vbms docs
    begin
      external_documents += download_vbms(download)
    rescue VBMS::ClientError => e
      has_error = true
      capture_error(e, download, :vbms_connection_error)
      return if !graceful
    end

    begin
      external_documents += download_vva(download)
    rescue VVA::ClientError => e
      capture_error(e, download, :vva_connection_error)
      has_error = true
      return if !graceful
    end

    create_documents(download, external_documents, has_error)
  end

  def download_vbms(download)
    external_documents = VBMSService.fetch_documents_for(download)
    download.update_attributes!(manifest_vbms_fetched_at: Time.zone.now)
    external_documents
  end

  def download_vva(download)
    external_documents = []
    if FeatureToggle.enabled?(:vva_service, user: download.user)
      external_documents = VVAService.fetch_documents_for(download)
      download.update_attributes!(manifest_vva_fetched_at: Time.zone.now)
    end
    external_documents
  end

  def create_documents(download, external_documents, has_error)
    # only indicate no_documents status if we've successfully completed fetching from services
    if !has_error && external_documents.empty?
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
