class RecordFetcher
  include ActiveModel::Model

  attr_accessor :record

  EXCEPTIONS = [VBMS::ClientError, VVA::ClientError].freeze

  def process
    if cached_content
      record.update(status: :success)
      return cached_content
    end
    content = record.service.v2_fetch_document_file(record)
    content = ImageConverterService.new(image: content, record: record).process
    S3Service.store_file(record.s3_filename, content)
    record.update(status: :success)
    content
  rescue *EXCEPTIONS
    record.update(status: :failed)
    nil
  # Catch StandardError in case there is an error to avoid records being stuck in pending state
  rescue StandardError => e
    record.update(status: :failed)
    raise e
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
