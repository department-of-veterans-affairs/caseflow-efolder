class Api::V1::FilesController < Api::V1::ApplicationController
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

  def user_id
    params.require(:user_id)
  end

  def id
    params[:id]
  end

  def download
    @download ||= Download.find_or_create_by_user_and_file(user_id, id)
  end
end
