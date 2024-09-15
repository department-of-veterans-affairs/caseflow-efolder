

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
    request = VBMS::Requests::ListDocuments.new(download.file_number)

    documents = send_and_log_request(download.file_number, request)
    Rails.logger.info("VBMS Document list length: #{documents.length}")
    documents
  end

  def self.v2_fetch_documents_for(veteran_file_number)
    documents = []

    if FeatureToggle.enabled?(:use_ce_api)
      response = VeteranFileFetcher.fetch_veteran_file_list(veteran_file_number: veteran_file_number)
      documents = JsonApiResponseAdapter.new.adapt_v2_fetch_documents_for(response)
    elsif FeatureToggle.enabled?(:vbms_pagination, user: RequestStore[:current_user])
      service = VBMS::Service::PagedDocuments.new(client: vbms_client)
      documents = call_and_log_service(service: service, vbms_id: veteran_file_number)[:documents]
    else
      request = VBMS::Requests::FindDocumentVersionReference.new(veteran_file_number)
      documents = send_and_log_request(veteran_file_number, request)
    end

    Rails.logger.info("VBMS Document list length: #{documents.length}")
    documents
  end

  def self.fetch_delta_documents_for(veteran_file_number, begin_date_range, end_date_range = Time.zone.now)
    documents = []

    if FeatureToggle.enabled?(:use_ce_api)
      response = VeteranFileFetcher.fetch_veteran_file_list_by_date_range(
        veteran_file_number: veteran_file_number,
        begin_date_range: begin_date_range,
        end_date_range: end_date_range
      )
      documents = JsonApiResponseAdapter.new.adapt_v2_fetch_documents_for(response)
    else
      request = VBMS::Requests::FindDocumentVersionReferenceByDateRange.new(veteran_file_number, begin_date_range, end_date_range)
      documents = send_and_log_request(veteran_file_number, request)
    end

    Rails.logger.info("VBMS Document list length: #{documents.length}")
    documents
  end

  def self.fetch_document_file(document)
    request = VBMS::Requests::FetchDocumentById.new(document.document_id)
    result = send_and_log_request(document.document_id, request)
    result&.content
  end

  def self.v2_fetch_document_file(document)
    if FeatureToggle.enabled?(:use_ce_api)
      # Not using #send_and_log_request because logging to MetricService implemeneted in CE API gem
      # Method call returns the response body, so no need to return response.content/body
      VeteranFileFetcher.get_document_content(doc_series_id: document.series_id)
    else
      request = VBMS::Requests::GetDocumentContent.new(document.document_id)
      result = send_and_log_request(document.document_id, request)
      result&.content
    end
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
      vbms_client.send_request(request)
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

  def self.vbms_client
    return @vbms_client if @vbms_client.present?

    @vbms_client = init_client
  end
end
