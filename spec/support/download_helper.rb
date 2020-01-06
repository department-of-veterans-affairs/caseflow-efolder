# Taken from the following:
# https://collectiveidea.com/blog/archives/2012/01/27/testing-file-downloads-with-capybara-and-chromedriver

module DownloadHelpers
  TIMEOUT = 60
  WORKDIR = Rails.root.join("tmp/downloads_all")

  module_function

  def downloads
    Dir.glob("#{WORKDIR}/*")
  end

  def download
    downloads.first
  end

  def download_content
    wait_for_download
    File.read(download)
  end

  def filesize
    File.size(download)
  end

  def wait_for_download
    Rails.logger.info("Waiting for download")
    counter = 0
    while counter < TIMEOUT do
      break if downloaded?
      sleep 1
      counter += 1
      Rails.logger.info("... waited #{counter}")
      Rails.logger.info("#{WORKDIR} contains: #{downloads.pretty_inspect}")
    end
  end

  def downloaded?
    !downloading? && downloads.any?
  end

  def downloading?
    downloads.grep(/\.part$/).any?
  end

  def clear_downloads
    FileUtils.rm_f(downloads)
  end
end
