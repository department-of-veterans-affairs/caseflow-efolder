class GetDownloadFilesJob < ActiveJob::Base
  queue_as :default

  def perform(download)
    download_documents = DownloadDocuments.new(download: download)
    download_documents.download_contents
    download_documents.package_contents
  end

  def max_attempts
    1
  end
end
