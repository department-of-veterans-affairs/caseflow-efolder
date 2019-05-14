# TODO: create Api::V2::ApplicationController
class Api::V2::ManifestsController < Api::V1::ApplicationController
  def start
    file_number = verify_veteran_file_number
    return if performed?

    manifest = Manifest.includes(:sources, :records).find_or_create_by_user(user: current_user, file_number: file_number)
    manifest.start!
    render json: json_manifests(manifest)
  end

  def refresh
    manifest = Manifest.find(params[:id])
    return record_not_found unless manifest
    return sensitive_record unless manifest.files_downloads.find_by(user: current_user)

    manifest.start!
    render json: json_manifests(manifest)
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

  def document_count
    manifest_id = params[:id]
    cache_key = "manifest-doc-count-#{manifest_id}"
    doc_count = Rails.cache.fetch(cache_key, expires_in: 2.hours) do
      doc_counter = DocumentCounter.new(manifest: Manifest.find(manifest_id))
      doc_counter.count
    end
    render json: { documents: doc_count }
  rescue ActiveRecord::RecordNotFound
    return record_not_found
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

  def bgs_service
    @bgs_service ||= BGSService.new
  end

  def veteran_not_found(file_number)
    render json: { status: "eFolder Express could not find an eFolder with the Veteran ID #{file_number}. Check to make sure you entered the ID correctly and try again." }, status: 400
  end

  def vso_denied_record
    forbidden("This efolder belongs to a Veteran you do not represent. Please contact your supervisor.")
  end

  def invalid_file_number
    render json: { status: "File number is invalid. Veteran IDs must be 8 or more characters and contain only numbers." }, status: 400
  end

  def verify_veteran_file_number
    file_number = request.headers["HTTP_FILE_NUMBER"]
    return missing_header("File Number") unless file_number

    return invalid_file_number unless bgs_service.valid_file_number?(file_number)

    fetch_veteran_by_file_number(file_number)
  end

  def fetch_veteran_by_file_number(file_number)
    begin
      veteran_info = bgs_service.fetch_veteran_info(file_number)
    rescue StandardError => e
      return sensitive_record if e.message.include?("Sensitive File - Access Violation")
      return vso_denied_record if e.message.include?("Power of Attorney of Folder is")
      raise e
    end

    return veteran_not_found(file_number) unless bgs_service.record_found?(veteran_info)

    veteran_info["file_number"] || file_number
  end
end
