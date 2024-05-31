class RecordFetcher < RecordFetcherBase

  def process
    s = Redis::Semaphore.new("record_#{record.id}".to_s,
                             url: Rails.application.secrets.redis_url_cache,
                             stale_client_timeout: 5,
                             expiration: SECONDS_TO_AUTO_UNLOCK)
    s.lock(SECONDS_TO_AUTO_UNLOCK)
    content_from_s3 || content_from_va_service
  rescue *EXCEPTIONS => e
    Rails.logger.error("Caught #{e}")
    nil
  ensure
    s&.unlock
  end

  private

  def content_from_va_service
    record.update(sourced: "VBMS")
    content = MetricsService.record("RecordFetcher fetch content from VA manifest source name: #{record.manifest_source.name} for file_number #{record.file_number}",
                                    service: record.manifest_source.name.downcase.to_sym,
                                    name: "v2_fetch_document_file") do
      record.service.v2_fetch_document_file(record)
    end

    # convert image to pdf
    content = image_converter(content)

    # store to s3
    content_store_to_s3(content)

    content
  end

end
