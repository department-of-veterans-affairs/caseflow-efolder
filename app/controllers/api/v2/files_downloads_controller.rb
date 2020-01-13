class Api::V2::FilesDownloadsController < Api::V2::ApplicationController
  before_action :files_download_exists?

  def start
    files_download.start!
    render json: json_files_downloads
  end

  def progress
    render json: json_files_downloads
  end

  def zip
    streaming_headers
    send_data (manifest.stream_zip! || ""), type: "application/zip", filename: manifest.package_filename
  end

  private

  def files_download_exists?
    return record_not_found unless files_download
  end

  def streaming_headers
    # Setting this to "no" will allow unbuffered responses for HTTP streaming applications
    # see https://piotrmurach.com/articles/streaming-large-zip-files-in-rails/
    headers["X-Accel-Buffering"] = "no"
    headers["Cache-Control"] ||= "no-cache"
  end

  def json_files_downloads
    ActiveModelSerializers::SerializableResource.new(
      manifest,
      each_serializer: Serializers::V2::ManifestSerializer
    ).as_json
  end

  def files_download
    @files_download ||= FilesDownload.includes(:manifest, :sources, :records)
                                     .find_by(manifest_id: params[:manifest_id], user_id: current_user.id)
  end

  def manifest
    @manifest ||= files_download.manifest
  end
end
