class Fetcher
  include ActiveModel::Model
  attr_accessor :document, :external_service

  def content(save_document_metadata: true)
    if save_document_metadata
      download_from_service_and_record
    else
      download_from_service
    end
  end

  private

  def cached_content
    @cached_content ||= S3Service.fetch_content(document.s3_filename)
  end

  def convert_from_tiff(result)
    MetricsService.record("Image Magick: Convert tiff to pdf",
                          service: :image_magick,
                          name: "convert") do
      base_path = File.join(Rails.application.config.download_filepath, "tiff_convert")
      Dir.mkdir(base_path) unless File.exist?(base_path)

      tiff_name = File.join(base_path, File.basename(document.s3_filename, ".*") + ".tiff")

      File.open(tiff_name, "wb") do |f|
        f.write(result)
      end

      document.update_attributes!(converted_mime_type: "application/pdf")

      image = MiniMagick::Image.open(tiff_name)
      image.format "pdf"
      pdf_version = image.to_blob

      pdf_version
    end
  end

  def download_from_service
    return cached_content if cached_content
    external_service.fetch_document_file(document).tap do |result|
      result = convert_from_tiff(result) if document.mime_type == "image/tiff"
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
