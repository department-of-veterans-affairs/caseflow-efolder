
class FakeVBMSService
  def self.set_error(error)
    @error = error
  end

  def self.fetch_document_file(document)
    sleep(3)
    if(document.id.even? && @error)
      raise VBMS::ClientError
    else
      "this is some document, woah!"
    end
  end
end


class DemoDownloadFileJob < ActiveJob::Base
  queue_as :default  
 
  def perform(download, errors)
    sleep(3)
    download.update_attributes!(status: :no_documents)
    download.update_attributes!(status: :pending_documents)

    download.documents.create(filename: "demo1.txt")
    download.documents.create(filename: "demo2.txt")
    download.documents.create(filename: "demo3.txt")
    download.documents.create(filename: "demo4.txt")

    FakeVBMSService.set_error(errors)
    download_documents = DownloadDocuments.new(download: download, vbms_service: FakeVBMSService)
    download_documents.perform
  end
end