class GetDownloadManifestJob < ActiveJob::Base
  queue_as :default

  def perform(download)
    vbms_documents = VBMSService.fetch_documents_for(download)

    if vbms_documents.empty?
      download.update_attributes!(status: :no_documents)
    else
      download_documents = DownloadDocuments.new(download: download, vbms_documents: vbms_documents)
      download_documents.create_documents
      download.update_attributes!(status: :pending_confirmation)
    end
  rescue VBMS::ClientError => e
    Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
    Raven.capture_exception(e)
    download.update_attributes!(status: :vbms_connection_error)
  rescue
    download.update_attributes!(status: :no_documents)
  end

  def max_attempts
    1
  end
end
