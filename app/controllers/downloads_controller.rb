class DownloadsController < ApplicationController
  before_action :authorize

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def new
    @search = Search.new
  end

  def create
    @search = Search.new(user: current_user, file_number: params[:file_number])

    if @search.perform!
      redirect_to download_url(@search.download)
    else
      render("new")
    end
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

  def retry
    @download = downloads.find(params[:id])

    @download.reset!
    start_download_files

    redirect_to download_url(@download)
  end

  def download
    download = downloads.find(params[:id])
    @download_documents = DownloadDocuments.new(download: download)
    @download_documents.fetch_zip_from_s3

    file_exists = @download_documents.zip_exists_locally?
    return record_not_found unless file_exists

    response.headers["Content-Length"] = (download.zipfile_size || File.size(@download_documents.zip_path)).to_s
    send_file @download_documents.zip_path
  end

  def record_not_found (exception)
    Rails.logger.error("Record not found... Exception #{exception.class}: #{exception.message}")
    render "not_found", locals: { id: params[:id] }, layout: "application", status: 404
  end

  def delete
    if current_user.css_id == ENV["TEST_USER_ID"]
      downloads.find(params[:id]).delete
    end
    redirect_to "/"
  end

  private

  def start_download_files
    @download.touch

    if @download.file_number =~ /DEMO/
      DemoGetDownloadFilesJob.perform_later(@download)
    else
      GetDownloadFilesJob.perform_later(@download)
    end
  end

  def downloads
    Download.active.where(user: current_user)
  end

  def recent_downloads
    @recent_downloads ||= downloads.where(status: [3, 4, 5, 6])
  end
  helper_method :recent_downloads

  def documents_in_progress
    @download.documents.pending
  end
  helper_method :documents_in_progress

  def completed_documents
    @download.documents.success
  end
  helper_method :completed_documents

  def failed_documents
    @download.documents.failed
  end
  helper_method :failed_documents

  def current_tab
    params[:current_tab] || (@download.complete? ? "completed" : "progress")
  end
  helper_method :current_tab

  def current_document_status
    { "progress": 0, "completed": 1, "errored": 2 }[current_tab.to_sym]
  end
  helper_method :current_document_status
end
