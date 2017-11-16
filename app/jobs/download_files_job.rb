class DownloadFilesJob < ActiveJob::Base
  queue_as :default

  def perform(download)
    download_documents = DownloadDocuments.new(download: download)

    download_documents.download_and_package
  end

  def max_attempts
    1
  end
end
