class Api::V2::ManifestsController < Api::V2::ApplicationController
  def start
    file_number = verify_veteran_file_number
    return if performed?

    manifest = Manifest.includes(:sources, :records).find_or_create_by_user(user: current_user, file_number: file_number)
    manifest.start!
    render json: json_manifests(manifest)
  rescue BGS::SensitivityLevelCheckFailure
    forbidden("This user does not have permission to access this information")
  end

  def refresh
    manifest = Manifest.find(params[:id])
    return record_not_found unless manifest
    return sensitive_record unless manifest.files_downloads.find_by(user: current_user)

    manifest.start!
    render json: json_manifests(manifest)
  rescue BGS::SensitivityLevelCheckFailure
    forbidden("This user does not have permission to access this information")
  end

  def progress
    files_download = nil
    distribute_reads do
      files_download ||= FilesDownload.find_with_manifest(manifest_id: params[:id], user_id: current_user.id)
    end
    return record_not_found unless files_download

    render json: json_manifests(files_download.manifest)
  end

  def history
    render json: recent_downloads, each_serializer: Serializers::V2::HistorySerializer
  end

  private

  def json_manifests(manifest)
    ActiveModelSerializers::SerializableResource.new(
      manifest,
      each_serializer: Serializers::V2::ManifestSerializer
    ).as_json
  end

  def recent_downloads
    @recent_downloads ||= distribute_reads { current_user.recent_downloads.to_a }
  end
end
