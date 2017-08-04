class Api::V1::DocumentsController < Api::V1::ApplicationController
  include RetryHelper

  def show
    document = Document.find(params[:id])
    # The line below enables document caching for a month.
    expires_in 30.days, public: true

    content = nil
    retry_when ActiveRecord::StaleObjectError, limit: 3 do
      content = document.fetcher.content
    end

    send_data(
      content,
      type: document.mime_type,
      disposition: "attachment",
      filename: document.filename
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
