# frozen_string_literal: true

# Translates JSON API responses into a format that's compatible with the legacy SOAP responses expected
# by most of caseflow-efolder
class JsonApiResponseAdapter
  def adapt_v2_fetch_documents_for(json_response)
    documents = []
    json_response.body["files"].each do |file_resp|
      documents.push(v2_fetch_documents_file_response(file_resp))
    end

    documents
  end

  private

  def v2_fetch_documents_file_response(file_json)
    system_data = file_json["currentVersion"]["systemData"]
    provider_data = file_json["currentVersion"]["providerData"]

    OpenStruct.new(
      document_id: file_json["currentVersionUuid"],
      series_id: file_json["uuid"],
      version: "1",
      type_description: provider_data["subject"],
      type_id: provider_data["documentTypeId"],
      doc_type: provider_data["documentTypeId"],
      subject: provider_data["subject"],
      received_at: provider_data["dateVaReceivedDocument"],
      source: provider_data["contentSource"],
      mime_type: system_data["mimeType"],
      alt_doc_types: nil,
      restricted: nil,
      upload_date: system_data["uploadedDateTime"]
    )
  end
end