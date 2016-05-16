class GetDownloadManifestJob < ActiveJob::Base
  queue_as :default

  def perform(download)
    vbms_documents = VBMSService.fetch_documents_for(download)


    if vbms_documents.empty?
      download.update_attributes!(status: :no_documents)
    else
      download.update_attributes!(status: :pending_confirmation)
      download_documents = DownloadDocuments.new(download: download, vbms_documents: vbms_documents)
      download_documents.create_documents
    end
  rescue
    download.update_attributes!(status: :no_documents)
  end

  def max_attempts
    1
  end
end
