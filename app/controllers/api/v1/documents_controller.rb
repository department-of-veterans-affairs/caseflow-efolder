class Api::V1::DocumentsController < Api::V1::ApplicationController
  before_action :can_access?

  def show
    fetch_result = document.fetch_content!(save_document_metadata: false)
    return document_download_failed(fetch_result[:error_kind]) if fetch_result[:error_kind]

    # Enable document caching for a month.
    expires_in 30.days, public: true

    send_data(
      fetch_result[:content],
      type: document.mime_type,
      disposition: "attachment",
      filename: document.filename
    )
  end

  private

  def document_download_failed(error_kind)
    status = 500
    message = "Caseflow eFolder failed to fetch document contents."

    if [:vva_error, :vbms_error].include?(error_kind)
      status = 502
      message = "An upstream dependency failed to fetch document contents."
    end

    render json: {
      "errors": [
        "title": "Document download failed",
        "detail": message
      ]
    }, status: status
  end

  def document
    @document ||= Document.find(params[:id])
  end

  def can_access?
    forbidden("sensitive record") if !document.can_be_access_by?(current_user)
  rescue ActiveRecord::RecordNotFound
    document_not_found
  end

  def document_not_found
    render json: {
      "errors": [
        "title": "Document not found",
        "detail": "A document with that ID was not found in our systems."
      ]
    }, status: 404
  end
end
