class RecordFetcher
  include ActiveModel::Model

  attr_accessor :record

  EXCEPTIONS = [VBMS::ClientError, VVA::ClientError].freeze

  def process
    return cached_content if cached_content
    content = record.service.fetch_document_file(record)
    content = convert_to_pdf(content)
    S3Service.store_file(record.s3_filename, content)
    record.update(status: :success)
    content
  rescue *EXCEPTIONS
    record.update(status: :failed)
    nil
  end

  private

  def convert_to_pdf(content)
    record.converted_mime_type = converted_mime_type
    ImageConverterService.new(image: content, mime_type: record.mime_type).process
  rescue ImageConverterService::ImageConverterError
    record.converted_mime_type = record.mime_type
    content
  end

  def converted_mime_type
    ImageConverterService.converted_mime_type(record.mime_type)
  end

  def cached_converted_content
    record.converted_mime_type = converted_mime_type
    @cached_converted_content ||= MetricsService.record("S3: fetch content for: #{record.s3_filename}",
                                                        service: :s3,
                                                        name: "fetch_content") do
      S3Service.fetch_content(record.s3_filename)
    end
  end

  def cached_original_content
    record.converted_mime_type = record.mime_type
    @cached_original_content ||= MetricsService.record("S3: fetch content for: #{record.s3_filename}",
                                                       service: :s3,
                                                       name: "fetch_content") do
      S3Service.fetch_content(record.s3_filename)
    end
  end

  def cached_content
    cached_converted_content || cached_original_content
  end
end
