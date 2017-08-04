require "vbms"

# Thin interface to all things VBMS
class ExternalApi::VBMSService
  def self.fetch_documents_for(download)
    @vbms_client ||= init_client

    request = if FeatureToggle.enabled?(:vbms_efolder_service_v1)
                VBMS::Requests::FindDocumentSeriesReference.new(download.file_number)
              else
                VBMS::Requests::ListDocuments.new(download.file_number)
              end
    documents = send_and_log_request(download.file_number, request)
    Rails.logger.info("VBMS Document list length: #{documents.length}")
    documents
  end

  def self.fetch_document_file(document)
    @vbms_client ||= init_client

    request = if FeatureToggle.enabled?(:vbms_efolder_service_v1)
                VBMS::Requests::GetDocumentContent.new(document.document_id)
              else
                VBMS::Requests::FetchDocumentById.new(document.document_id)
              end
    result = send_and_log_request(document.document_id, request)
    result && result.content
  end

  def self.vbms_config
    config = Rails.application.secrets.vbms.clone

    %w(keyfile saml key cacert cert).each do |file|
      config[file] = File.join(config["env_dir"], config[file])
    end

    config
  end

  def self.init_client
    return VBMS::Client.from_env_vars(logger: RailsVBMSLogger.new,
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

  def self.send_and_log_request(id, request)
    name = request.class.name.split("::").last
    MetricsService.record("#{request.class} for #{id}",
                          service: :vbms,
                          name: name) do
      @response = @vbms_client.send_request(request)
    end
  rescue VBMS::ClientError => e
    Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
    raise e
  end
  @response
end

class RailsVBMSLogger
  def log(event, data)
    case event
    when :request
      if data[:response_code] != 200
        Rails.logger.error(
          "VBMS HTTP Error #{data[:response_code]}\n" \
          "VBMS Response #{data[:response_body]}"
        )
      end
    end
  end
end
