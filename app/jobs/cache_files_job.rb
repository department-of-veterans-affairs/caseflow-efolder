class CacheFilesJob < ActiveJob::Base
  queue_as :default

  def perform(download)
    download_documents = DownloadDocuments.new(download: download)

    download_documents.cache_contents_in_s3(only_cache: true)
  end

  def max_attempts
    1
  end
end
