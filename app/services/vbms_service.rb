require "vbms"

# Thin interface to all things VBMS
class VBMSService
  def self.fetch_documents_for(download)
    @client ||= init_client

    request = if FeatureToggle.enabled?(:vbms_efolder_service_v1)
                VBMS::Requests::FindDocumentSeriesReference.new(download.file_number)
              else
                VBMS::Requests::ListDocuments.new(download.file_number)
              end
    @client.send_request(request)
  rescue => e
    Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
    raise VBMS::ClientError
  end

  def self.fetch_document_file(document)
    @client ||= init_client

    request = if FeatureToggle.enabled?(:vbms_efolder_service_v1)
                VBMS::Requests::GetDocumentContent.new(document.document_id)
              else
                VBMS::Requests::FetchDocumentById.new(document.document_id)
              end
    result = @client.send_request(request)
    result && result.content
  rescue => e
    Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
    raise VBMS::ClientError
  end

  def self.vbms_config
    config = Rails.application.secrets.vbms.clone

    %w(keyfile saml key cacert cert).each do |file|
      config[file] = File.join(config["env_dir"], config[file])
    end

    config
  end

  def self.init_client
    return VBMS::Client.from_env_vars(
      logger: RailsVBMSLogger.new,
      env_name: ENV["CONNECT_VBMS_ENV"]
    ) if Rails.application.secrets.vbms["env"]

    VBMS::Client.new(
      vbms_config["url"],
      vbms_config["keyfile"],
      vbms_config["saml"],
      vbms_config["key"],
      vbms_config["keypass"],
      vbms_config["cacert"],
      vbms_config["cert"],
      RailsVBMSLogger.new
    )
  end

  class RailsVBMSLogger
    def log(event, data)
      case event
      when :request
        Rails.logger.info("VBMS Request Sent: #{data[:request]} ")
        if data[:response_code] != 200
          Rails.logger.error(
            "VBMS HTTP Error #{data[:response_code]}\n" \
            "VBMS Response #{data[:response_body]}"
          )
        else
          Rails.logger.info("VBMS Reponse Code #{data[:response_code]}")
        end
      end
    end
  end
end
