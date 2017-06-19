class FakeDocumentService
  cattr_accessor :errors, :max_time

  def self.fetch_document_file(_document)
    sleep(rand(FakeDocumentService.max_time))
    fail VBMS::ClientError if FakeDocumentService.errors && rand(5) == 3
    fail VVA::ClientError if FakeDocumentService.errors && rand(5) == 2
    "this is some document, woah!"
  end
end

class DemoGetDownloadFilesJob < ActiveJob::Base
  queue_as :default

  def perform(download)
    demo = DemoGetDownloadManifestJob::DEMOS[download.file_number] || DemoGetDownloadManifestJob::DEMOS["DEMODEFAULT"]

    FakeDocumentService.errors = demo[:error]
    FakeDocumentService.max_time = demo[:max_file_load]

    download_documents = DownloadDocuments.new(
      download: download,
      vbms_service: FakeDocumentService,
      vva_service: FakeDocumentService
    )
    download_documents.download_and_package
  end
end
