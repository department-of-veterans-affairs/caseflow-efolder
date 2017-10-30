class Api::V1::FilesController < Api::V1::ApplicationController
  include RetryHelper

  def index
    return missing_header("File Number") unless id
    render json: json_files
  end

  private

  def json_files
    download.prepare_files_for_api!(start_download: download?)

    ActiveModelSerializers::SerializableResource.new(
      download,
      each_serializer: Serializers::V1::DownloadSerializer
    ).as_json

  rescue ActiveRecord::StaleObjectError
    retry_when ActiveRecord::StaleObjectError, limit: 3 do
      Rails.logger.info "StaleObjectError. Retrying file #: #{download.file_number}, user: #{download.user_id}"
      # Reload the download so we have a fresh copy.
      # Otherwise, we'll just throw a StaleObjectError again.
      download.reload.prepare_files_for_api!(start_download: download?)

      ActiveModelSerializers::SerializableResource.new(
        download,
        each_serializer: Serializers::V1::DownloadSerializer
      ).as_json
    end
  end

  # A caller can pass a download parameter in the url: `?download=true`.
  # If it is present, then we return true from download? to signal
  # that we want to download the content of the files from VBMS to S3.
  def download?
    params[:download]
  end

  def id
    request.headers["HTTP_FILE_NUMBER"]
  end

  def download
    @download ||= Download.find_or_create_by_user_and_file(current_user.id, id)
  end
end
