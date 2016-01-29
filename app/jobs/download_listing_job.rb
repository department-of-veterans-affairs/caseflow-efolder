class DownloadListingJob < ActiveJob::Base
  queue_as :default

  def perform(download)
    documents = EFolderExpress.download_listing(download)

    # enqueue each download separately
    documents.each { |document|
      DocumentDownloadJob.perform_later(document)
    }
  end
end