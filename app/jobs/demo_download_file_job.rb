class FakeVBMSService
  def self.fetch_document_file(document)
    sleep(3)
    "this is some document, woah!"
  end
end

class DemoDownloadFileJob < ActiveJob::Base
  queue_as :default  
 
  def perform(download, error)
    sleep(3)
    download.update_attributes!(status: :no_documents) && return if error
    download.update_attributes!(status: :pending_documents)

    download.documents.create(filename: "demo1.txt")
    download.documents.create(filename: "demo2.txt")
    download.documents.create(filename: "demo3.txt")
    download.documents.create(filename: "demo4.txt")

    download_documents = DownloadDocuments.new(download: download, vbms_service: FakeVBMSService)
    download_documents.perform
  end
end