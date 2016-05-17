class FakeVBMSService
  attr_writer :error

  def self.fetch_document_file(document)
     sleep(3)
     fail VBMS::ClientError if document.id.even? && @error
     "this is some document, woah!"
  end
end

class DemoGetDownloadFilesJob < ActiveJob::Base
  queue_as :default

  def perform(download, errors)
    download_documents = DownloadDocuments.new(download: download, vbms_service: FakeVBMSService)
    download_documents.download_contents
    download_documents.package_contents
  end
end
