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

  def cached_content
    @cached_content ||= MetricsService.record("S3: fetch content for: #{document.s3_filename}",
                                              service: :s3,
                                              name: "fetch_content") do
      S3Service.fetch_content(document.s3_filename)
    end
  end

  def download_from_service
    return cached_content if cached_content

    converted_image = ImageConverterService.new(
      image: external_service.fetch_document_file(document), mime_type: document.mime_type
    ).process
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
