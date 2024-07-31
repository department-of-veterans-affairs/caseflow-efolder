class RecordFetcherBase
  include ActiveModel::Model

  attr_accessor :record

  protected

  def content_from_s3
    record.update(sourced: "S3")
    return false if BaseController.dependencies_faked_for_CEAPI?

    @content_from_s3 ||= MetricsService.record("RecordFetcher fetch content from S3 filename: #{record.s3_filename} for file_number #{record.file_number}",
                                               service: :s3,
                                               name: "content_from_s3") do
      S3Service.fetch_content(record.s3_filename)
    end
  end

  def image_converter(content)
    MetricsService.record("ImageConverterService for #{record.s3_filename}",
                          service: :image_converter,
                          name: "image_converter_service") do
      ImageConverterService.new(image: content, record: record).process
    end
  end

  def content_store_to_s3(content)
    if BaseController.dependencies_faked_for_CEAPI?
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

end
