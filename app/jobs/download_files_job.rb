class DownloadFilesJob < ActiveJob::Base
  queue_as :default

  # Sometimes, a VA backend will randomly fail. When we retry, it generally works.
  # We will explicitly rescue and retry here, because otherwise the first
  # failure will be logged to Sentry. For this error, we only want the last one
  # to be logged to Sentry.
  rescue_from EOFError do
    retry_job
  end

  def perform(download)
    download_documents = DownloadDocuments.new(download: download)

    download_documents.download_and_package
  end

  def max_attempts
    1
  end
end
