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
    self.response_body = manifest.stream_zip! || ""
  end

  private

  def files_download_exists?
    return record_not_found unless files_download
  end

  def streaming_headers
    headers["Content-Type"] = "application/zip"
    headers["Content-disposition"] = "attachment; filename=\"#{manifest.package_filename}\""
    headers["Content-Length"] = manifest.zipfile_size.to_s

    # Setting this to "no" will allow unbuffered responses for HTTP streaming applications
    # see https://piotrmurach.com/articles/streaming-large-zip-files-in-rails/
    headers["X-Accel-Buffering"] = "no"
    headers["Cache-Control"] ||= "no-cache"

    # Set this to prevent the Rack::ETag middleware from buffering the response.
    # Note: Affects rack 2.2.2
    #
    # See: https://github.com/rack/rack/issues/1619#issuecomment-606315714
    headers['Last-Modified'] = '0'
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
