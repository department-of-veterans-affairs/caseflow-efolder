# Converts images to PDFs
class ImageConverterService
  include ActiveModel::Model
  attr_accessor :image, :mime_type

  def process
    # If we do not handle converting this mime_type, don't do any processing.
    return image if self.class.converted_mime_type(mime_type) == mime_type

    convert_tiff_to_pdf if mime_type == "image/tiff" && tiff?
  end

  # If the converter converts this mime_type then this returns the converted type
  # otherwise it just returns the original type.
  def self.converted_mime_type(mime_type)
    if FeatureToggle.enabled?(:convert_tiff_images)
      return "application/pdf" if mime_type == "image/tiff"
    end

    mime_type
  end

  private

  # Adding a magic number check based on this recommendation: https://imagetragick.com/
  def tiff?
    "MM\u0000*" == image[0..3] || "II*\u0000" == image[0..3]
  end

  def convert_tiff_to_pdf
    MetricsService.record("Image Magick: Convert tiff to pdf",
                          service: :image_magick,
                          name: "image_magick_convert_tiff_to_pdf") do
      base_path = File.join(Rails.application.config.download_filepath, "tiff_convert")
      FileUtils.mkdir_p(base_path) unless File.exist?(base_path)

      filename = SecureRandom.hex[0..16].to_s

      tiff_name = File.join(base_path, "#{filename}.tiff")

      File.open(tiff_name, "wb") do |f|
        f.write(image)
      end

      pdf_name = File.join(base_path, "#{filename}.pdf")

      MiniMagick::Tool::Convert.new do |convert|
        convert << tiff_name
        convert << pdf_name
      end

      File.open(pdf_name, "r", &:read)
    end
  end
end
