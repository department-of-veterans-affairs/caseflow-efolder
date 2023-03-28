class Api::V2::RecordsController < Api::V2::ApplicationController
  before_action :validate_access

  def show
    result = record.fetch!
    return document_failed if record.failed?

    # Only cache if we're not returning an error
    enable_caching

    response.headers['Accept-Ranges'] = 'bytes'
    # If the request is a head request return the content length and type.
    if request.head?
      response.headers['Content-Length'] = result.bytesize.to_s
        head :ok, content_type: record.mime_type
    # If the request has a range header 
    elsif request.headers['HTTP_RANGE']
      # set range(0-1023) to range variable
      _, range = request.headers['HTTP_RANGE'].split('bytes=')
      # Split from (0) and to (1023) to variables and convert to integers
        from, to = range.split('-').map(&:to_i)
        # if there is not a end in the range set it to the end of the file
        to = result.bytesize - 1 unless to
        #Set the range length
        length = to - from + 1
        # Set response header Content-Range to be bytes 0-1023/total size
        response.headers['Content-Range'] = "bytes #{from}-#{to}/#{result.bytesize}"
        # Set respnse header Content-Length to the length of the range
        response.headers['Content-Length'] = "#{length}"
        # Set Status to 206 Partial Content
        self.status = 206
        # https://apidock.com/rails/v5.2.3/ActionController/DataStreaming/send_file_headers%21
        # send headers
        send_file_headers!(disposition: 'attachment', type: record.mime_type, filename: record.filename)
        # Set header back to full record length and mime type
        response.headers['Content-Type'] = record.mime_type
        response.headers['Content-Length'] ||= result.bytesize.to_s
        # Prevent Rack::ETag from calculating a digest over body
        response.headers['Last-Modified'] = Time.now.utc.strftime("%a, %d %b %Y %T GMT")
        # set response content type to match record
        self.content_type = record.mime_type
        # set the response body to be 
        stream = response.stream
        result.each do |chunk|
          stream.write chunk
        end
    else
      self.status = 200
      send_file_headers!(disposition: 'attachment', type: record.mime_type, filename: record.filename)
        response.headers['Content-Type'] = record.mime_type
        response.headers['Content-Length'] ||= result.bytesize.to_s
        # Prevent Rack::ETag from calculating a digest over body
        response.headers['Last-Modified'] = Time.now.utc.strftime("%a, %d %b %Y %T GMT")
        self.content_type = record.mime_type
        self.response_body = result
    end

    # send_data(
    #   result,
    #   type: record.mime_type,
    #   disposition: "attachment",
    #   filename: record.s3_filename
    # )
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
    @record ||= Record.includes(:manifest_source).where(version_id: version_id).order(created_at: :desc).first
  end

  def version_id
    "{" + params[:version_id] + "}"
  end

  def validate_access
    return record_not_found unless record
    sensitive_record unless record.accessible_by?(current_user)
  end
end
