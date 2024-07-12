class Api::V2::RecordsController < Api::V2::ApplicationController
  before_action :validate_access

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

  private

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

  def record
    @record ||= Record.includes(:manifest_source).where(version_id: version_id).order(created_at: :desc).first
  end

  def version_id
    "{" + params[:version_id] + "}"
  end

  def validate_access
    return record_not_found unless record
    sensitive_record unless record.accessible_by?(current_user)
  end
end
