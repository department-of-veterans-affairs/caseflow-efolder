class RecordFetcher
  include ActiveModel::Model

  attr_accessor :record

  EXCEPTIONS = [VBMS::ClientError, VVA::ClientError].freeze

  def process
    return cached_content if cached_content
    content = record.service.fetch_document_file(record)
    content = ImageConverterService.new(image: content, mime_type: record.mime_type).process
    S3Service.store_file(record.s3_filename, content)
    record.update(status: :success)
    content
  rescue *EXCEPTIONS => e
    record.update(status: :failed)
    nil
  end

  private

  def cached_content
    @cached_content ||= MetricsService.record("S3: fetch content for: #{record.s3_filename}",
                                              service: :s3,
                                              name: "fetch_content") do
      S3Service.fetch_content(record.s3_filename)
    end
  end
end