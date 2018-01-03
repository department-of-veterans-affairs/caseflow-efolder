# Converts images to PDFs
class ImageConverterService
  class ImageConverterError < StandardError; end

  include ActiveModel::Model
  attr_accessor :image, :mime_type

  def process
    # If we do not handle converting this mime_type, don't do any processing.
    return image if self.class.converted_mime_type(mime_type) == mime_type

    convert_tiff_to_pdf if mime_type == "image/tiff"
  end

  # If the converter converts this mime_type then this returns the converted type
  # otherwise it just returns the original type.
  def self.converted_mime_type(mime_type)
    if FeatureToggle.enabled?(:convert_tiff_images)
      return "application/pdf" if mime_type == "image/tiff"
    end

    mime_type
  end

  # :nocov:
  def convert_tiff_to_pdf
    url = "http://localhost:5000/tiff-convert"

    curl = Curl::Easy.new(url)
    curl.multipart_form_post = true

    MetricsService.record("Image Magick: Convert tiff to pdf",
                          service: :image_magick,
                          name: "image_magick_convert_tiff_to_pdf") do
      Tempfile.open(["tiff_to_convert", ".tiff"]) do |file|
        file.binmode
        file.write(image)
        curl.http_post(Curl::PostField.file("file", file.path))
      end

      fail ImageConverterError if curl.status != "200 OK"
    end

    curl.body
  end
  # :nocov:
end
