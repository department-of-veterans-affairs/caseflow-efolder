class Fetcher
  include ActiveModel::Model
  attr_accessor :document, :external_service

  def content(save_document_metadata: true)
    return cached_content if cached_content
    cache_in_s3(save_document_metadata: save_document_metadata)
  end

  private

  def cached_content
    @cached_content ||= S3Service.fetch_content(document.s3_filename)
  end

  def cache_in_s3(save_document_metadata: true)
    document.update_attributes!(started_at: Time.zone.now) if save_document_metadata

    result = external_service.fetch_document_file(document)
    S3Service.store_file(document.s3_filename, result)

    document.update_attributes!(
      completed_at: Time.zone.now,
      download_status: :success,
      size: result.try(:bytesize)
    ) if save_document_metadata
    result
  end
end
