class Api::V1::DocumentsController < Api::V1::ApplicationController
  def show
    begin
      document = Document.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      document_not_found
    end

    # Enable document caching for a month.
    expires_in 30.days, public: true

    success, content = document.fetch_content!(save_document_metadata: false)
    if success
      send_data(
        content,
        type: document.mime_type,
        disposition: "attachment",
        filename: document.filename
      ) if success
    else
      document_download_filed
    end
  end

  private

  def document_download_filed
    render json: {
      "errors": [
        "status": "502",
        "title": "Document download failed",
        "detail": "An upstream dependency failed to fetch document contents."
      ]
    }, status: 502
  end

  def document_not_found
    render json: {
      "errors": [
        "status": "404",
        "title": "Document not found",
        "detail": "A document with that ID was not found in our systems."
      ]
    }, status: 404
  end
end
