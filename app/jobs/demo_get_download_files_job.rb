class DemoGetDownloadFilesJob < ActiveJob::Base
  queue_as :default

  def perform(download)
    demo = DemoGetDownloadManifestJob::DEMOS[download.file_number] || DemoGetDownloadManifestJob::DEMOS["DEMODEFAULT"]

    Fakes::DocumentService.errors = demo[:error]
    Fakes::DocumentService.max_time = demo[:max_file_load]

    download_documents = DownloadDocuments.new(download: download)
    download_documents.download_and_package
  end
end
