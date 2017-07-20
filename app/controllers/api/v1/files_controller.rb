class Api::V1::FilesController < Api::V1::ApplicationController
  before_action :verify_authentication_token

  def show
    render json: json_files
  rescue ActiveRecord::RecordNotFound
    file_not_found
  end

  private

  def json_files
    download.prepare_files_for_api!(start_download: download?)

    ActiveModelSerializers::SerializableResource.new(
      download,
      each_serializer: Serializers::V1::DownloadSerializer
    ).as_json
  end

  # A caller can pass a download parameter in the url: `?download=true`.
  # If it is present, then we return true from download? to signal
  # that we want to download the content of the files from VBMS to S3.
  def download?
    params[:download]
  end

  def file_not_found
    render json: {
      "errors": [
        "status": "404",
        "title": "File not found",
        "detail": "A case file with that ID was not found in our system."
      ]
    }, status: 404
  end

  def verify_authentication_token
    return unauthorized unless api_key
  end

  def api_key
    @api_key ||= authenticate_with_http_token { |token, _options| token == ENV["FILES_ENDPOINT_TOKEN"] }
  end

  def station_id
    params[:station_id]
  end

  def css_id
    params[:css_id]
  end

  def id
    params[:id]
  end

  def current_user
    @current_user ||= User.find_or_create_by(css_id: css_id, station_id: station_id)
  end

  def download
    @download ||= Download.find_or_create_by_user_and_file(current_user, id)
  end
end
