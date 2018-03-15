require "fileutils"

##
# Cleans all files in the temporary download files directory
#
class CleanDownloadFilesJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Cleaning all temporary files..."
    FileUtils.rm_rf(Rails.application.config.download_filepath)
  end

  def max_attempts
    1
  end
end
