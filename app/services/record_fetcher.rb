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
    # Every time we can't find the file in S3 and are asked to convert the version from
    # VBMS, we try to do the conversion, even if it failed last time. In case some change
    # has enabled it to be converted this time.
    converted_content = ImageConverterService.new(image: content, mime_type: record.mime_type).process
    record.update_attributes!(conversion_status: :conversion_success)
    converted_content
  rescue ImageConverterService::ImageConverterError
    record.update_attributes!(conversion_status: :conversion_failed)
    content
  end

  def cached_content
    @cached_content ||= MetricsService.record("S3: fetch content for: #{record.s3_filename}",
                                              service: :s3,
                                              name: "fetch_content") do
      S3Service.fetch_content(record.s3_filename)
    end
  end
end
