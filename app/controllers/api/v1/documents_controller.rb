class Api::V1::DocumentsController < Api::V1::ApplicationController
  before_action :can_access?

  def show
    # The line below enables document caching for a month.
    expires_in 30.days, public: true

    send_data(
      document.fetcher.content(save_document_metadata: false),
      type: document.mime_type,
      disposition: "attachment",
      filename: document.filename
    )
  rescue ActiveRecord::RecordNotFound
    document_not_found
  end

  private

  def document
    @document ||= Document.find(params[:id])
  end

  def can_access?
    forbidden("sensitive record") if !::BGSService.new.check_sensitivity(document.download.file_number)
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
