class DownloadAllManifestJob < ActiveJob::Base
  queue_as :default

  def perform(download)
    begin
      # sequentially download documents from all services
      DownloadVBMSManifestJob.perform_now(download)
      DownloadVVAManifestJob.perform_now(download)
    rescue VBMS::ClientError => e
      capture_error(e, download, :vbms_connection_error)
    rescue VVA::ClientError => e
      capture_error(e, download, :vva_connection_error)
    end
  end

  def capture_error(e, download, status)
    Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
    Raven.capture_exception(e)
    download.update_attributes!(status: status)
    nil
  end
end
