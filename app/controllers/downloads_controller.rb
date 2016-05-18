class DownloadsController < ApplicationController
  def new
    @download = Download.new
    @recent_downloads = Download.where(status: [3, 4])
  end

  def create
    @download = Download.create!(file_number: params[:file_number])

    if @download.demo?
      DemoGetDownloadManifestJob.perform_later(@download)
    else
      GetDownloadManifestJob.perform_later(@download)
    end

    redirect_to download_url(@download)
  end

  def start
    @download = Download.find(params[:id])
    @download.update_attributes!(status: :pending_documents)

    if @download.file_number =~ /DEMO/
      DemoGetDownloadFilesJob.perform_later(@download, false)
    else
      GetDownloadFilesJob.perform_later(@download)
    end

    redirect_to download_url(@download)
  end

  def show
    @download = Download.find(params[:id])

    respond_to do |format|
      format.html
      format.json { render json: @download.to_json }
    end
  end

  def progress
    @download = Download.find(params[:id])
    render "_progress", layout: false
  end

  def download
    @download_documents = DownloadDocuments.new(download: Download.find(params[:id]))

    send_file @download_documents.zip_path
  end
end
