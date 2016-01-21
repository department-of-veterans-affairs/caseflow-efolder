class DownloadsController < ApplicationController
  def new
  	@download = Download.new
  end

  def create
  	@download = Download.create()
  	redirect_to status_download_url(@download)
  end

  def status
  end
end
