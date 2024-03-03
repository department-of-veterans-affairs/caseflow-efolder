require "vbms"

class RailsVBMSLogger
  def log(event, data)
    case event
    when :request
      if data[:response_code] != 200
        name = data[:request].class.name.split("::").last

        Rails.logger.error(
          "VBMS HTTP Error #{data[:response_code]}\n" \
          "VBMS #{name} Response #{data[:response_body]}"
        )
      end
    end
  end
end

class ExternalApi::VBMSService
  def self.fetch_documents_for(download)
    @vbms_client ||= init_client

    request = VBMS::Requests::ListDocuments.new(download.file_number)

    documents = send_and_log_request(download.file_number, request)
    Rails.logger.info("VBMS Document list length: #{documents.length}")
    documents
  end

  def v2_fetch_documents_for(veteran_file_number)
    initialize_vbms_client

    if Rails.deploy_env?(:prodtest)
      # Return fake response grab document from eFolder Prod S3 bucket
      fake_request = Fakes::VbmsService::GetDocumentContent.new(veteran_file_number)
      result = send_and_log_request(veteran_file_number, fake_request)
    else
      request = VBMS::Requests::GetDocumentContent.new(veteran_file_number)
      result = send_and_log_request(veteran_file_number, request)
    end

    result&.content
  end

  def self.fetch_delta_documents_for(veteran_file_number, begin_date_range, end_date_range = Time.zone.now)
    @vbms_client || init_client

    request = VBMS::Requests::FindDocumentVersionReferenceByDateRange.new(veteran_file_number, begin_date_range, end_date_range)
    documents = send_and_log_request(veteran_file_number, request)
    documents
  end

  def self.fetch_document_file(document)
    @vbms_client ||= init_client

    request = VBMS::Requests::FetchDocumentById.new(document.document_id)
    result = send_and_log_request(document.document_id, request)
    result&.content
  end

  def self.v2_fetch_document_file(document)
    @vbms_client ||= init_client

    request = if Rails.deploy_env?(:prodtest)
                # return fake response grab document from eFolder Prod S3 bucket
                Fake::VBMS::GetDocumentContent.new(document.document_id)
              else
                VBMS::Requests::GetDocumentContent.new(document.document_id)
              end

    result = send_and_log_request(document.document_id, request)
    result&.content
  end

  def self.init_client
    VBMS::Client.from_env_vars(logger: RailsVBMSLogger.new,
                               env_name: ENV["CONNECT_VBMS_ENV"],
                               use_forward_proxy: FeatureToggle.enabled?(:vbms_forward_proxy))
  end

  def self.send_and_log_request(id, request)
    name = request.class.name.split("::").last
    MetricsService.record("#{request.class} for #{id}",
                          service: :vbms,
                          name: name) do
      @vbms_client.send_request(request)
    end
  end

  def self.call_and_log_service(service:, vbms_id:)
    name = service.class.name.split("::").last
    MetricsService.record("call #{service.class} for #{vbms_id}",
                          service: :vbms,
                          name: name) do
      service.call(file_number: vbms_id)
    end
  end
end
