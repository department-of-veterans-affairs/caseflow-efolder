class Api::V2::FilesDownloadsController < Api::V1::ApplicationController
  before_action :set_files_download

  def start
    files_download.start!
    render json: json_files_downloads
  end

  def progress
    render json: json_files_downloads
  end

  def zip
    streaming_headers
    self.response_body = manifest.stream_zip! || ""
  end

  private

  def set_files_download
    return record_not_found unless files_download
  end

  def streaming_headers
    headers["Content-Type"] = "application/zip"
    headers["Content-disposition"] = "attachment; filename=\"#{manifest.package_filename}\""
    headers["Content-Length"] = manifest.zipfile_size.to_s

    # Setting this to "no" will allow unbuffered responses for HTTP streaming applications
    headers["X-Accel-Buffering"] = "no"
    headers["Cache-Control"] ||= "no-cache"
  end

  def json_files_downloads
    ActiveModelSerializers::SerializableResource.new(
      manifest,
      each_serializer: Serializers::V2::FilesDownloadSerializer
    ).as_json
  end

  def files_download
    @files_download ||= FilesDownload.includes(:manifest).find_by(manifest_id: params[:manifest_id], user_id: current_user.id)
  end

  def manifest
    @manifest ||= files_download.manifest
  end

  def record_not_found
    render json: {
      "errors": [
        "title": "Record not found",
        "detail": "A record with that ID was not found in our systems."
      ]
    }, status: 404
  end
end
