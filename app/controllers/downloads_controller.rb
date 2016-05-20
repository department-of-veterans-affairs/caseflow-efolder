class DownloadsController < ApplicationController
  def new
    @download = Download.new
  end

  def create
    @download = Download.new(file_number: params[:file_number])

    if !@download.demo?
      @error = :veteran_not_found if !@download.case_exists?
      @error = :access_denied if !@download.can_access?
      render "new" and return if @error
    end
    @download.save!

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

  private

  def recent_downloads
    @recent_downloads ||= Download.where(status: [3, 4])
  end
  helper_method :recent_downloads
end
