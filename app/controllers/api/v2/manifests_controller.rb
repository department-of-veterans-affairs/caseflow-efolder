# TODO: create Api::V2::ApplicationController
class Api::V2::ManifestsController < Api::V1::ApplicationController
  before_action :set_file_number, except: :history
  before_action :validate_file_number, except: :history
  before_action :validate_access, except: :history

  def start
    manifest.start!
    render json: json_manifests
  end

  def progress
    render json: json_manifests
  end

  def history
    render json: recent_downloads, each_serializer: Serializers::V2::ManifestSerializer
  end

  private

  def json_manifests
    ActiveModelSerializers::SerializableResource.new(
      manifest,
      each_serializer: Serializers::V2::ManifestSerializer
    ).as_json
  end

  def recent_downloads
    @recent_downloads ||= current_user.recent_downloads
  end

  attr_reader :file_number

  def set_file_number
    case action_name
    when "start"
      return missing_header("File Number") unless request.headers["HTTP_FILE_NUMBER"]
      @file_number = request.headers["HTTP_FILE_NUMBER"]
    when "progress"
      begin
        @file_number = Manifest.find(params[:id]).file_number
      rescue ActiveRecord::RecordNotFound
        return record_not_found
      end
    end
  end

  def validate_file_number
    invalid_file_number unless bgs_service.valid_file_number?(file_number)
  end

  def validate_access
    forbidden("sensitive record") unless bgs_service.check_sensitivity(file_number)
  end

  def manifest
    @manifest ||= Manifest.find_or_create_by_user(user: current_user, file_number: file_number)
  end

  def bgs_service
    @bgs_service ||= BGSService.new
  end

  def invalid_file_number
    render json: { status: "File Number is invalid, must be 8 or 9 digits" }, status: 400
  end
end
