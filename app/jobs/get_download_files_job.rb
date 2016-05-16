class GetDownloadFilesJob < ActiveJob::Base
  queue_as :default

  def perform(download)
  end

  def max_attempts
    1
  end
end
