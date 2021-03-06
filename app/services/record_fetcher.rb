class RecordFetcher
  include ActiveModel::Model

  attr_accessor :record

  EXCEPTIONS = [VBMS::ClientError, VVA::ClientError].freeze
  SECONDS_TO_AUTO_UNLOCK = 90

  def process
    s = Redis::Semaphore.new("record_#{record.id}".to_s,
                             url: Rails.application.secrets.redis_url_cache,
                             stale_client_timeout: 5,
                             expiration: SECONDS_TO_AUTO_UNLOCK)
    s.lock(SECONDS_TO_AUTO_UNLOCK)
    content_from_s3 || content_from_va_service
  rescue *EXCEPTIONS => error
    Rails.logger.error("Caught #{error}")
    nil
  ensure
    s&.unlock
  end

  private

  def content_from_va_service
    content = MetricsService.record("#{record.manifest_source.name} v2_fetch_document_file",
                                    service: record.manifest_source.name.downcase.to_sym,
                                    name: "v2_fetch_document_file") do
      record.service.v2_fetch_document_file(record)
    end
    content = MetricsService.record("ImageConverterService for #{record.s3_filename}",
                                    service: :image_converter,
                                    name: "image_converter_service") do
      ImageConverterService.new(image: content, record: record).process
    end
    MetricsService.record("S3: RecordFetcher store content for #{record.s3_filename}",
                          service: :s3,
                          name: "content_from_va_service") do
      S3Service.store_file(record.s3_filename, content)
    end
    content
  end

  def content_from_s3
    @content_from_s3 ||= MetricsService.record("S3: RecordFetcher fetch content for: #{record.s3_filename}",
                                               service: :s3,
                                               name: "content_from_s3") do
      S3Service.fetch_content(record.s3_filename)
    end
  end
end
