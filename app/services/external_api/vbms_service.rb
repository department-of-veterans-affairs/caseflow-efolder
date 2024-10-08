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
    request = VBMS::Requests::ListDocuments.new(download.file_number)

    documents = send_and_log_request(download.file_number, request)
    Rails.logger.info("VBMS Document list length: #{documents.length}")
    documents
  end

  def self.v2_fetch_documents_for(veteran_file_number)
    documents = []

    if FeatureToggle.enabled?(:use_ce_api)
      verify_user_veteran_access(veteran_file_number)
      response = VeteranFileFetcher.fetch_veteran_file_list(
        veteran_file_number: veteran_file_number,
        claim_evidence_request: claim_evidence_request
      )
      documents = process_fetch_veteran_file_list_response(response)
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
      verify_user_veteran_access(veteran_file_number)
      response = VeteranFileFetcher.fetch_veteran_file_list_by_date_range(
        veteran_file_number: veteran_file_number,
        claim_evidence_request: claim_evidence_request,
        begin_date_range: begin_date_range,
        end_date_range: end_date_range
      )
      documents = process_fetch_veteran_file_list_response(response)
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
      verify_user_veteran_access(document.file_number)
      # Not using #send_and_log_request because logging to MetricService implemeneted in CE API gem
      VeteranFileFetcher.get_document_content(doc_series_id: document.series_id, claim_evidence_request: claim_evidence_request)
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

  def self.verify_user_veteran_access(veteran_file_number)
    return if RequestStore[:current_user].blank?

    raise "User does not have permission to access this information" unless
      SensitivityChecker.new.sensitivity_levels_compatible?(
        user: RequestStore[:current_user],
        veteran_file_number: veteran_file_number
      )
  end

  def self.process_fetch_veteran_file_list_response(response)
    documents = JsonApiResponseAdapter.new.adapt_v2_fetch_documents_for(response)

    # We want to be notified of any API responses that are not parsable
    if documents.nil?
      ex = RuntimeError.new("API response could not be parsed: #{response}")
      ExceptionLogger.capture(ex)
    end

    documents || []
  end

  def self.claim_evidence_request
    ClaimEvidenceRequest.new(
      user_css_id: allow_user_info? ? RequestStore[:current_user].css_id : ENV['CLAIM_EVIDENCE_VBMS_USER'],
      station_id: allow_user_info? ? RequestStore[:current_user].station_id : ENV['CLAIM_EVIDENCE_STATION_ID']
    )
  end
    
  def self.allow_user_info?
    RequestStore[:current_user].present? && FeatureToggle.enabled?(:send_current_user_cred_to_ce_api)
  end
end
