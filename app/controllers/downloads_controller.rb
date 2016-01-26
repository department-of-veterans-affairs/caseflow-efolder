class DownloadsController < ApplicationController
  def new
    @download = Download.new
  end

  def create
    @download = Download.create!(file_number: params[:file_number])

    if @download.file_number =~ /DEMO/
      DemoDownloadFileJob.perform_later(@download, false)
    else
      DownloadFileJob.perform_later(@download)
    end

    redirect_to download_url(@download)
  end

  def show
    @download = Download.find(params[:id])
  end

  def download
    @download_documents = DownloadDocuments.new(download: Download.find(params[:id]))

    send_file @download_documents.zip_path
  end
end
