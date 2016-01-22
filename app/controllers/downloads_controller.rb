class DownloadsController < ApplicationController
  def new
  	@download = Download.new
  end

  def create
  	@download = Download.create!(file_number: params[:file_number])
  	redirect_to download_url(@download)
  end

  def show
  	@download = Download.find(params[:id])
  end
end
