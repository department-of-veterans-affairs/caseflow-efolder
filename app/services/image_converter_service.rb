# Converts images to PDFs
class ImageConverterService
  class ImageConverterError < StandardError; end

  include ActiveModel::Model
  attr_accessor :image, :record

  def process
    # If we do not handle converting this mime_type, don't do any processing.
    return image if self.class.converted_mime_type(record.mime_type) == record.mime_type

    converted_image = convert
    record.update_attributes!(conversion_status: :conversion_success)
    converted_image
  rescue ImageConverterError
    record.update_attributes!(conversion_status: :conversion_failed)

    image
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

  EXCEPTIONS = [Errno::ECONNREFUSED, HTTPClient::ReceiveTimeoutError].freeze

  # :nocov:
  # update
  def convert_tiff_to_pdf
    url = "http://localhost:5000/tiff-convert"

    clnt = HTTPClient.new
    response = nil
    
    MetricsService.record("Image Magick: Convert tiff to pdf",
                          service: :image_magick,
                          name: "image_magick_convert_tiff_to_pdf") do
      Tempfile.open(["tiff_to_convert", ".tiff"]) do |file|
        file.binmode
        file.write(image)
        file.rewind

        body = { "file" => file }
        response = clnt.post(url, body)
      end

      raise ImageConverterError if response.status != 200
    end

    response.body
  rescue *EXCEPTIONS
    raise ImageConverterError
  end
  # :nocov:

  def convert
    case record.mime_type
    when "image/tiff"
      convert_tiff_to_pdf
    else
      image
    end
  end
end
