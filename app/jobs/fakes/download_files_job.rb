class Fakes::DownloadFilesJob < ActiveJob::Base
  queue_as :med_priority

  def perform(download)
    demo = Efolder::Fakes::DocumentService::DEMOS[download.file_number] || Casflow::Fakes::DocumentService::DEMOS["DEMODEFAULT"]

    Casflow::Fakes::DocumentService.errors = demo[:error]
    Casflow::Fakes::DocumentService.max_time = demo[:max_file_load]

    download_documents = DownloadDocuments.new(download: download)
    download_documents.download_and_package
  end
end
