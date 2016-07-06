class RestartStalledDownloadsJob < ActiveJob::Base
  queue_as :default

  def perform
    Download.where(status: [3, 4]).each do |download|
      start_download_files(download) if download.stalled?
    end
  end

  private

  def start_download_files(download)
    Rails.logger.info "Stalled job detected... Restarting download: #{download.id}"

    download.touch

    if download.file_number =~ /DEMO/
      DemoGetDownloadFilesJob.perform_later(download)
    else
      GetDownloadFilesJob.perform_later(download)
    end
  end
end
