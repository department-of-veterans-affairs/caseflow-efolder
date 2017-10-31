class Api::V1::DocumentsController < Api::V1::ApplicationController
  def show
    begin
      document = Document.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      return document_not_found
    end

    # Enable document caching for a month.
    expires_in 30.days, public: true

    fetch_result = document.fetch_content!(save_document_metadata: false)
    return document_download_failed(fetch_result[:error_kind]) if fetch_result[:error_kind]
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

    if error_kind == :vva_error || error_kind == :vbms_error
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

  def document_not_found
    render json: {
      "errors": [
        "title": "Document not found",
        "detail": "A document with that ID was not found in our systems."
      ]
    }, status: 404
  end
end
