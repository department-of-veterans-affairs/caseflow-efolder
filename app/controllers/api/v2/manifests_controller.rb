# TODO: create Api::V2::ApplicationController
class Api::V2::ManifestsController < Api::V1::ApplicationController
  before_action :can_access?

  def index
    return missing_header("File Number") unless file_number
    render json: json_manifests
  end

  private

  def json_manifests
    manifest.start!

    ActiveModelSerializers::SerializableResource.new(
      manifest,
      each_serializer: Serializers::V2::ManifestSerializer
    ).as_json
  end

  def file_number
    request.headers["HTTP_FILE_NUMBER"]
  end

  def can_access?
    forbidden("sensitive record") unless BGSService.new.check_sensitivity(file_number)
  end

  def manifest
    @manifest ||= Manifest.find_or_create_by_user(user: current_user, file_number: file_number)
  end
end
