class Api::V1::DocumentsController < Api::V1::ApplicationController
  before_action :verify_feature_enabled

  def show
    document = Document.find(params[:id])
    streaming_headers(document.mime_type, document.filename)
    self.response_body = document.stream_file
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

  def verify_feature_enabled
    # TODO: scope this to a current user
    unauthorized unless FeatureToggle.enabled?(:reader_api)
  end
end