class DownloadAllManifestJob < ActiveJob::Base
  queue_as :default

  def perform(download)
    # sequentially download documents from all services
    error, vbms_documents = DownloadVBMSManifestJob.perform_now(download)
    if error
      download.update_attributes!(status: error)
      return
    end

    error, vva_documents = DownloadVVAManifestJob.perform_now(download)
    if error
      download.update_attributes!(status: error)
      return
    end

    external_documents = vbms_documents + vva_documents

    # update status of download
    if external_documents.empty?
      download.update_attributes!(status: :no_documents)
    else
      download.update_attributes!(status: :pending_confirmation)
    end
    external_documents
  end
end
