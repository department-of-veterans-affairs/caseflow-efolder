class Fetcher
  include ActiveModel::Model
  attr_accessor :document, :external_service

  def content(save_document_metadata: true)
    return cached_content if cached_content
    if save_document_metadata
      download_from_service_and_record
    else
      download_from_service
    end
  end

  private

  def cached_content
    @cached_content ||= (S3Service.fetch_content(document.s3_filename) ||
      S3Service.fetch_content(document.old_s3_filename))
  end

  def download_from_service
    external_service.fetch_document_file(document).tap do |result|
      S3Service.store_file(document.s3_filename, result)
    end
  end

  def download_from_service_and_record
    document.update_attributes!(started_at: Time.zone.now)
    download_from_service.tap do |result|
      document.update_attributes!(
        completed_at: Time.zone.now,
        download_status: :success,
        size: result.try(:bytesize)
      )
    end
  end
end
