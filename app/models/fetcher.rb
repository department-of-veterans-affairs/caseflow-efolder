class Fetcher
  include ActiveModel::Model
  attr_accessor :document, :external_service

  def content(save_document_metadata: true)
    if save_document_metadata
      download_from_service_and_record
    else
      download_from_service
    end
  end

  private

  def converted_mime_type
    ImageConverterService.converted_mime_type(document.mime_type)
  end

  def cached_content
    MetricsService.record("S3: fetch content for: #{document.s3_filename}",
                          service: :s3,
                          name: "fetch_content") do
      S3Service.fetch_content(document.s3_filename)
    end
  end

  def cached_converted_content
    # Don't need to do anything if the mime_type is not converted.
    return if converted_mime_type == document.mime_type

    document.s3_stored_file_mime_type = converted_mime_type
    @cached_converted_content ||= cached_content
  end

  def cached_original_content
    document.s3_stored_file_mime_type = document.mime_type
    @cached_original_content ||= cached_content
  end

  def cached_converted_or_original_content
    @cached_converted_or_original_content ||= (cached_converted_content || cached_original_content)
  end

  def download_from_service
    return cached_converted_or_original_content if cached_converted_or_original_content

    content_from_service = external_service.fetch_document_file(document)

    begin
      document.s3_stored_file_mime_type = converted_mime_type
      converted_image = ImageConverterService.new(
        image: content_from_service, mime_type: document.mime_type).process
    rescue ImageConverterService::ImageConverterError
      document.s3_stored_file_mime_type = document.mime_type
      converted_image = content_from_service
    end
    S3Service.store_file(document.s3_filename, converted_image)

    converted_image
  end

  def download_from_service_and_record
    document.update_attributes!(started_at: Time.zone.now)
    download_from_service.tap do |result|
      document.update_attributes!(
        completed_at: Time.zone.now,
        download_status: :success,
        size: result.try(:bytesize)
      )
    end
  end
end
