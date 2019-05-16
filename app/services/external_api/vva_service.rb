require "vva"

# Thin interface to talk to Virtual VA
class ExternalApi::VVAService
  def self.fetch_documents_for(download)
    @vva_client ||= init_client
    documents ||= MetricsService.record("VVA: get document list for: #{download.file_number}",
                                        service: :vva,
                                        name: "document_list.get_by_claim_number") do
      @vva_client.document_list.get_by_claim_number(download.file_number)
    end
    Rails.logger.info("VVA Document list length: #{documents.length}")
    documents
  end

  def self.v2_fetch_documents_for(file_number)
    @vva_client ||= init_client
    documents ||= MetricsService.record("VVA: get document list for: #{file_number}",
                                        service: :vva,
                                        name: "document_list.get_by_claim_number") do
      @vva_client.document_list.get_by_claim_number(file_number)
    end
    Rails.logger.info("VVA Document list length: #{documents.length}")
    documents
  end

  def self.fetch_document_file(document)
    @vva_client ||= init_client
    result ||= MetricsService.record("VVA: fetch document content for: #{document.document_id}",
                                     service: :vva,
                                     name: "document_content.get_by_document_id") do
      @vva_client.document_content.get_by_document_id(
        document_id: document.document_id,
        source: document.source,
        format: document.preferred_extension,
        jro: document.jro,
        ssn: document.ssn
      )
    end
    result&.content
  end

  # TODO: remove when switched to VBMS eFolder API
  def self.v2_fetch_document_file(document)
    fetch_document_file(document)
  end

  def self.init_client
    forward_proxy_url = FeatureToggle.enabled?(:vva_forward_proxy) ? ENV["CONNECT_VVA_PROXY_BASE_URL"] : nil
    VVA::Services.new(
      wsdl: Rails.application.config.vva_wsdl,
      username: ENV["VVA_USERNAME"],
      password: ENV["VVA_PASSWORD"],
      ssl_cert_key_file: ENV["VVA_KEY_LOCATION"],
      ssl_cert_file: ENV["VVA_CERT_LOCATION"],
      ssl_ca_cert: ENV["VVA_CA_CERT_LOCATION"],
      forward_proxy_url: forward_proxy_url
    )
  end
end
