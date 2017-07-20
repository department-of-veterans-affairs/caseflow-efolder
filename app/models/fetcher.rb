class Fetcher
  include ActiveModel::Model
  attr_accessor :document, :external_service

  def content
    document.update_attributes!(started_at: Time.zone.now)
    result = S3Service.fetch_content(document.s3_filename) || cache_in_s3
    document.update_attributes!(
      completed_at: Time.zone.now,
      download_status: :success,
      size: result.try(:bytesize)
    )
    result
  end

  private

  def cache_in_s3
    result = external_service.fetch_document_file(document)
    S3Service.store_file(document.s3_filename, result)
    result
  end
end
