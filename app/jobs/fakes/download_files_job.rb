class Fakes::DownloadFilesJob < ActiveJob::Base
  queue_as :med_priority

  def perform(download)
    demo = Fakes::DocumentService::DEMOS[download.file_number] || Fakes::DocumentService::DEMOS["DEMODEFAULT"]

    Fakes::DocumentService.errors = demo[:error]
    Fakes::DocumentService.max_time = demo[:max_file_load]

    download_documents = DownloadDocuments.new(download: download)
    download_documents.download_and_package
  end
end
