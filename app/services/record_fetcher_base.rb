class RecordFetcherBase
  include ActiveModel::Model

  attr_accessor :record

  EXCEPTIONS = [VBMS::ClientError, VVA::ClientError].freeze
  SECONDS_TO_AUTO_UNLOCK = 90

  private

  def content_from_s3
    return false if BaseController.dependencies_faked?
    record.update(sourced: "S3")
    @content_from_s3 ||= MetricsService.record("RecordFetcher fetch content from S3 filename: #{record.s3_filename} for file_number #{record.file_number}",
                                               service: :s3,
                                               name: "content_from_s3") do
      S3Service.fetch_content(record.s3_filename)
    end
  end

  def content_store_to_s3(content)
    if BaseController.dependencies_faked?
      save_path = Rails.root.join('tmp', 'temp_pdf.pdf')
      IO.binwrite(save_path, content)
    else
      MetricsService.record("RecordFetcher S3 store content for #{record.s3_filename}",
                            service: :s3,
                            name: "content_from_va_service") do
        S3Service.store_file(record.s3_filename, content)
      end
    end
  end

  def image_converter(content)
    MetricsService.record("ImageConverterService for #{record.s3_filename}",
                          service: :image_converter,
                          name: "image_converter_service") do
      ImageConverterService.new(image: content, record: record).process
    end
  end

end
