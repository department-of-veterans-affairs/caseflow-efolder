class Api::V1::DocumentsController < Api::V1::ApplicationController
  before_action :authorize

  def show
    document = Document.find(params[:id])
    # The line below enables document caching for a month.
    expires_in 30.days, public: true

    send_data(
      document.fetcher.content,
      type: document.mime_type,
      disposition: "attachment",
      filename: document.filename
    )
  rescue ActiveRecord::RecordNotFound
    document_not_found
  end

  private

  def authorize
    unauthorized unless current_user.can? "Reader"
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
