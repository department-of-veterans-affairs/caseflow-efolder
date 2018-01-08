class Api::V2::RecordsController < Api::V1::ApplicationController
  before_action :validate_access, only: :show

  # /api/v2/records/:id
  # This API returns document content
  def show
    result = record.fetch!
    return document_failed if record.failed?

    # Only cache if we're not returning an error
    enable_caching

    send_data(
      result,
      type: record.mime_type,
      disposition: "attachment",
      filename: record.s3_filename
    )
  end

  # /api/v2/manifests/manifest_id/records
  # This API endpoint is used by eX UI and will kick off
  # the job to download files from VBMS/VVA and save in s3
  def index
    return record_not_found unless user_manifest
    render json: json_records
  end

  private

  def json_records
    user_manifest.save_files_and_package!

    ActiveModelSerializers::SerializableResource.new(
      user_manifest,
      each_serializer: Serializers::V2::UserManifestSerializer
    ).as_json
  end

  def document_failed
    render json: {
      "errors": [
        "title": "Document download failed",
        "detail": "An upstream dependency failed to fetch document contents."
      ]
    }, status: 502
  end

  def enable_caching
    expires_in 30.days, public: true
  end

  def user_manifest
    UserManifest.includes(:manifest)
                .find_by(manifest_id: params[:manifest_id], user_id: current_user.id)
  end

  def record
    @record ||= Record.includes(:manifest_source).find(params[:id])
  end

  def validate_access
    forbidden("sensitive record") unless record.accessible_by?(current_user)
  rescue ActiveRecord::RecordNotFound
    record_not_found
  end

  def record_not_found
    render json: {
      "errors": [
        "title": "Record not found",
        "detail": "A record with that ID was not found in our systems."
      ]
    }, status: 404
  end
end
