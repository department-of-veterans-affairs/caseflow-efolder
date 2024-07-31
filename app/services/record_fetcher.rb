class RecordFetcher < RecordFetcherBase

  EXCEPTIONS = [VBMS::ClientError, VVA::ClientError].freeze
  SECONDS_TO_AUTO_UNLOCK = 90

  def process
    s = Redis::Semaphore.new("record_#{record.id}".to_s,
                             url: Rails.application.secrets.redis_url_cache,
                             stale_client_timeout: 5,
                             expiration: SECONDS_TO_AUTO_UNLOCK)
    MetricsService.record("RecordFetcher Semaphore lock from VA manifest source name: #{record.manifest_source.name} for file_number #{record.file_number}",
                           service: record.manifest_source.name.downcase.to_sym,
                           name: "recordfetcher_semaphore_lock") do                        
      s.lock(SECONDS_TO_AUTO_UNLOCK)
    end
    content_from_s3 || content_from_va_service
  rescue *EXCEPTIONS => error
    Rails.logger.error("Caught #{error}")
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

    content = image_converter(content)

    if BaseController.dependencies_faked_for_CEAPI?
      save_path = Rails.root.join('tmp', 'temp_pdf.pdf')
      IO.binwrite(save_path, content)
    else
      content_store_to_s3(content)
    end
    content
  end

end
