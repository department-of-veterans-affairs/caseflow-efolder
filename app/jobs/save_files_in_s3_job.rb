# frozen_string_literal: true

class SaveFilesInS3Job < ApplicationJob
  queue_as :default

  def perform(download)
    download_documents = DownloadDocuments.new(download: download)

    download_documents.download_contents(save_locally: false)
  end

  def max_attempts
    1
  end
end
