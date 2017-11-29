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

    # efolder issue #675: Set the download's status to manifest_fetch_error
    # if this job fails and the download's status == fetching_manifest.
  rescue StandardError => e
    download.update_attributes!(status: :manifest_fetch_error) if download.fetching_manifest?
    raise e
  end
end
