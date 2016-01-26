class DownloadFileJob < ActiveJob::Base
  queue_as :default  
 
  def perform(download)
    vbms_documents = VBMSService.fetch_documents_for(download)
 
    download.update_attributes!(status: :no_documents) && return if vbms_documents.empty?
    download.update_attributes!(status: :pending_documents)

    download_documents = DownloadDocuments.new(download: download, vbms_documents: vbms_documents)
    download_documents.perform
    
  rescue
    download.update_attributes!(status: :no_documents)
  end

  def max_attempts
    1
  end
end