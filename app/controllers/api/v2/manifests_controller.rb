# TODO: create Api::V2::ApplicationController
class Api::V2::ManifestsController < Api::V1::ApplicationController
  def start
    file_number = request.headers["HTTP_FILE_NUMBER"]
    return missing_header("File Number") unless file_number

    return invalid_file_number unless bgs_service.valid_file_number?(file_number)
    return veteran_not_found(file_number) if bgs_service.fetch_veteran_info(file_number).nil?
    return sensitive_record unless bgs_service.check_sensitivity(file_number)

    manifest = Manifest.find_or_create_by_user(user: current_user, file_number: file_number)
    manifest.start!
    render json: json_manifests(manifest)
  end

  def progress
    manifest = Manifest.find(params[:id])
    return record_not_found unless manifest
    return sensitive_record unless bgs_service.check_sensitivity(file_number)

    render json: json_manifests(manifest)
  end

  def history
    render json: recent_downloads, each_serializer: Serializers::V2::ManifestSerializer
  end

  private

  def json_manifests(manifest)
    ActiveModelSerializers::SerializableResource.new(
      manifest,
      each_serializer: Serializers::V2::ManifestSerializer
    ).as_json
  end

  def recent_downloads
    @recent_downloads ||= current_user.recent_downloads
  end

  def bgs_service
    @bgs_service ||= BGSService.new
  end

  def veteran_not_found(file_number)
    render json: { status: "eFolder Express could not find an eFolder with the Veteran ID #{file_number}. Check to make sure you entered the ID correctly and try again." }, status: 400
  end

  def invalid_file_number
    render json: { status: "File number is invalid. Veteran IDs must be 8 or more characters and contain only numbers." }, status: 400
  end
end
