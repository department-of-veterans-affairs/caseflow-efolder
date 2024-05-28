class RecordApiFetcher
  include ActiveModel::Model

  attr_accessor :record

  EXCEPTIONS = [VBMS::ClientError, VVA::ClientError].freeze

  def process
    content_from_s3 || content_from_va_service
  rescue *EXCEPTIONS => error
    Rails.logger.error("Caught #{error}")
    nil
  end

  private

  def content_from_va_service
    record.update(sourced: "VBMS")
    content = MetricsService.record("RecordFetcher fetch content from VA - S3 MISS: #{record.manifest_source.name} for file_number #{record.file_number}",
                                    service: record.manifest_source.name.downcase.to_sym,
                                    name: "v2_fetch_document_file") do
      record.service.v2_fetch_document_file(record)
    end
    MetricsService.record("ImageConverterService for #{record.s3_filename}",
                          service: :image_converter,
                          name: "image_converter_service") do
      ImageConverterService.new(image: content, record: record).process
    end
    content
  end

  def content_from_s3
    record.update(sourced: "S3")
    @content_from_s3 ||= MetricsService.record("RecordFetcher fetch content from S3 filename: #{record.s3_filename} for file_number #{record.file_number}",
                                               service: :s3,
                                               name: "content_from_s3") do
      S3Service.fetch_content(record.s3_filename)
    end
  end
end
