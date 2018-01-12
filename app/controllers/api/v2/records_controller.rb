class Api::V2::RecordsController < Api::V1::ApplicationController
  before_action :validate_access

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
