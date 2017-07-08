class DownloadManifestJob < ActiveJob::Base
  queue_as :default

  def perform(download)
    external_documents = VBMSService.fetch_documents_for(download)

    if FeatureToggle.enabled?(:vva_service)
      external_documents += VVAService.fetch_documents_for(download)
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
    download.update_attributes!(status: :pending_confirmation)

  rescue VBMS::ClientError => e
    capture_error(e, download, :vbms_connection_error)
  rescue VVA::ClientError => e
    capture_error(e, download, :vva_connection_error)
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
