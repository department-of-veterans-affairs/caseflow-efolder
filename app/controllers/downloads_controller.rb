class DownloadsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def new
    @download = Download.new
  end

  def create
    return if redirect_to_download_if_exists

    @download = downloads.new(file_number: sanitized_file_number)
    check_error unless @download.demo?
    render("new") && return if @error

    @download.save!

    if @download.demo?
      DemoGetDownloadManifestJob.perform_later(@download)
    else
      GetDownloadManifestJob.perform_later(@download)
    end

    redirect_to download_url(@download)
  end

  def start
    @download = downloads.find(params[:id])
    @download.update_attributes!(status: :pending_documents)

    start_download_files
    redirect_to download_url(@download)
  end

  def show
    @download = downloads.find(params[:id])

    respond_to do |format|
      format.html
      format.json { render json: @download.to_json }
    end
  end

  def progress
    @download = downloads.find(params[:id])

    if @download.stalled?
      Rails.logger.info "Stalled job detected... Restarting download: #{@download.id}"
      start_download_files
    end

    render "_progress", layout: false
  end

  def download
    @download_documents = DownloadDocuments.new(download: downloads.find(params[:id]))
    @download_documents.fetch_zip_from_s3

    send_file @download_documents.zip_path
  end

  def record_not_found
    render "not_found"
  end

  private

  def redirect_to_download_if_exists
    @download = downloads.where(file_number: sanitized_file_number).first
    redirect_to(download_url(@download)) && (return true) if @download
  end

  def sanitized_file_number
    (params[:file_number] || "").strip
  end

  def start_download_files
    @download.touch

    if @download.file_number =~ /DEMO/
      DemoGetDownloadFilesJob.perform_later(@download)
    else
      GetDownloadFilesJob.perform_later(@download)
    end
  end

  def check_error
    if !@download.case_exists?
      @error = :veteran_not_found
    elsif !@download.can_access?
      @error = :access_denied
    end
  end

  def downloads
    Download.where(user_id: current_user.id, user_station_id: current_user.station_id)
  end

  def recent_downloads
    @recent_downloads ||= downloads.where(status: [3, 4, 5, 6])
  end
  helper_method :recent_downloads

  def current_tab
    params[:current_tab] || (@download.complete? ? "completed" : "progress")
  end
  helper_method :current_tab

  def current_document_status
    { "progress": 0, "completed": 1, "errored": 2 }[current_tab.to_sym]
  end
  helper_method :current_document_status
end
