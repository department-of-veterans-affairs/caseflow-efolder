# frozen_string_literal: true

class Api::V1::FilesController < Api::V1::ApplicationController
  before_action :can_access?

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

  def can_access?
    forbidden("sensitive record") if !BGSService.new.check_sensitivity(id)
  end

  def download
    @download ||= Download.find_or_create_by_user_and_file(current_user.id, id)
  end
end
