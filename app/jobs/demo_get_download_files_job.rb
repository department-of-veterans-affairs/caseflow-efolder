class FakeService
  cattr_accessor :errors, :max_time

  def self.fetch_document_file(_document)
    sleep(rand(FakeService.max_time))
    fail VBMS::ClientError if FakeService.errors && rand(5) == 3
    fail VVA::ClientError if FakeService.errors && rand(5) == 2
    "this is some document, woah!"
  end
end

class DemoGetDownloadFilesJob < ActiveJob::Base
  queue_as :default

  def perform(download)
    demo = DemoGetDownloadManifestJob::DEMOS[download.file_number] || DemoGetDownloadManifestJob::DEMOS["DEMODEFAULT"]

    FakeService.errors = demo[:error]
    FakeService.max_time = demo[:max_file_load]

    download_documents = DownloadDocuments.new(download: download, vbms_service: FakeService, vva_service: FakeService)
    download_documents.download_and_package
  end
end
