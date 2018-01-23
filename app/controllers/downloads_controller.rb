class DownloadsController < ApplicationController
  before_action :authorize

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def new
    @search = Search.new
  end

  def create
    @search = Search.new(user: current_user, file_number: params[:file_number])

    if @search.valid_file_number? && @search.perform!
      redirect_to download_url(@search.download)
    else
      render("new")
    end
  end

  def react
    if can_access_react_app?
      render "_react", layout: false
    else
      redirect_to "/"
    end
  end

  def initial_react_data
    {
      authenticityToken: form_authenticity_token,
      dropdownUrls: dropdown_urls,
      feedbackUrl: feedback_url,
      recentDownloads: recent_downloads,
      userDisplayName: current_user.display_name
    }.to_json
  end
  helper_method :initial_react_data

  def dropdown_urls
    [
      {
        title: "Help",
        link: url_for(controller: "/help", action: "show")
      },
      {
        title: "Send Feedback",
        link: feedback_url,
        target: "_blank"
      },
      {
        title: "Sign out",
        link: url_for(controller: "/sessions", action: "destroy")
      }
    ]
  end
  helper_method :dropdown_urls

  def can_access_react_app?
    FeatureToggle.enabled?(:efolder_react_app, user: current_user) || Rails.env.development?
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

    streaming_headers(download)
    self.response_body = @download_documents.stream_zip_from_s3
  end

  def record_not_found(exception)
    Rails.logger.error("Record not found... Exception #{exception.class}: #{exception.message}")
    render "not_found", locals: { id: params[:id] }, layout: "application", status: 404
  end

  def delete
    return if ENV["TEST_USER_ID"].nil?
    downloads.find(params[:id]).delete
    redirect_to "/"
  end

  def should_show_vva_coachmarks?
    current_user.vva_coachmarks_view_count < 2
  end
  helper_method :should_show_vva_coachmarks?

  def increment_vva_coachmarks_status
    return if !vva_feature_enabled?

    current_user.vva_coachmarks_view_count += 1
    current_user.save!

    render text: ""
  end

  private

  def streaming_headers(download)
    headers["Content-Type"] = "application/zip"
    headers["Content-disposition"] = "attachment; filename=\"#{download.package_filename}\""
    headers["Content-Length"] = download.zipfile_size.to_s

    # Setting this to "no" will allow unbuffered responses for HTTP streaming applications
    headers["X-Accel-Buffering"] = "no"
    headers["Cache-Control"] ||= "no-cache"
  end

  def start_download_files
    @download.touch

    if @download.demo?
      Fakes::DownloadFilesJob.perform_later(@download)
    else
      DownloadFilesJob.perform_later(@download)
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

  def downloaded_from_vbms
    @download.documents.where(downloaded_from: "VBMS").count
  end
  helper_method :downloaded_from_vbms

  def downloaded_from_vva
    @download.documents.where(downloaded_from: "VVA").count
  end
  helper_method :downloaded_from_vva

  def current_tab
    params[:current_tab] || (@download.complete? ? "completed" : "progress")
  end
  helper_method :current_tab

  def current_document_status
    { "progress": 0, "completed": 1, "errored": 2 }[current_tab.to_sym]
  end
  helper_method :current_document_status
end
