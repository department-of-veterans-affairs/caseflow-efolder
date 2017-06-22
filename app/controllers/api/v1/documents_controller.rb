class Api::V1::DocumentsController < Api::V1::ApplicationController

  def show
    document = Document.find(params[:id])
    document.fetch_content_and_save
    send_file(
      document.filepath,
      type: document.mime_type,
      disposition: "attachment; filename=#{document.filename}"
    )
  rescue ActiveRecord::RecordNotFound
    document_not_found
  end

  private

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