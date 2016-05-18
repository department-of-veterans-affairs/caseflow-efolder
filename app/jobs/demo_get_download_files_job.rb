class FakeVBMSService
  cattr_accessor :errors, :max_time

  def self.fetch_document_file(document)
    sleep(rand(FakeVBMSService.max_time))
    fail VBMS::ClientError if FakeVBMSService.errors && rand(5) == 3
    "this is some document, woah!"
  end
end

class DemoGetDownloadFilesJob < ActiveJob::Base
  queue_as :default

  def perform(download, _errors)
    demo = DemoGetDownloadManifestJob::DEMOS[download.file_number] || DemoGetDownloadManifestJob::DEMOS["DEMODEFAULT"]

    FakeVBMSService.errors = demo[:error]
    FakeVBMSService.max_time = demo[:max_file_load]

    download_documents = DownloadDocuments.new(download: download, vbms_service: FakeVBMSService)
    download_documents.download_contents
    download_documents.package_contents
  end
end
