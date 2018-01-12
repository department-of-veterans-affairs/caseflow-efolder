class Api::V2::FilesDownloadsController < Api::V1::ApplicationController
  def start
    return record_not_found unless files_download
    files_download.start!
    render json: json_files_downloads
  end

  def progress
    return record_not_found unless files_download
    render json: json_files_downloads
  end

  private

  def json_files_downloads
    ActiveModelSerializers::SerializableResource.new(
      files_download,
      each_serializer: Serializers::V2::FilesDownloadSerializer
    ).as_json
  end

  def files_download
    @files_download ||= FilesDownload.includes(:manifest).find_by(manifest_id: params[:manifest_id], user_id: current_user.id)
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
