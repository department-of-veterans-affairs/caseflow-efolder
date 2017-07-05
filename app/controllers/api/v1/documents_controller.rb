class Api::V1::DocumentsController < Api::V1::ApplicationController
  before_action :verify_feature_enabled

  def show
    document = Document.find(params[:id])
    streaming_headers(document.mime_type, document.filename)
    # By setting the response body directly to an enumerator
    # Rails will use the enumerator to send the data element by element,
    # calling next on the enumerator to get the next chunk of data.
    self.response_body = document.fetcher.stream
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
