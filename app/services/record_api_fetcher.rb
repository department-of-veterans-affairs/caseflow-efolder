class RecordApiFetcher < RecordFetcherBase

  def process
    content_from_s3 || content_from_va_service
  rescue *EXCEPTIONS => e
    Rails.logger.error("Caught #{e}")
    nil
  end

  private

  def content_from_va_service
    record.update(sourced: "VBMS")
    content = MetricsService.record("RecordFetcher fetch content from VA manifest - API source name: #{record.manifest_source.name} for file_number #{record.file_number}",
                                    service: record.manifest_source.name.downcase.to_sym,
                                    name: "v2_fetch_document_file") do
      record.service.v2_fetch_document_file(record)
    end

    image_converter(content)
  end


end
