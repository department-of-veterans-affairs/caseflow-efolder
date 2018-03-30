class DownloadFilesJob < ApplicationJob
  queue_as :med_priority

  def perform(download)
    RequestStore.store[:current_user] = download.user

    download_documents = DownloadDocuments.new(download: download)

    download_documents.download_and_package
  end

  def max_attempts
    1
  end
end
