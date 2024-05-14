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
    current_version = file_json["currentVersion"]
    system_data = current_version["systemData"]
    provider_data = current_version["providerData"]

    OpenStruct.new(
      document_id: file_json["currentVersionUuid"],
      series_id: file_json["uuid"],
      version: "1",
      type_description: nil,
      type_id: file_json["documentTypeId"],
      doc_type: file_json["documentTypeId"],
      subject: provider_data["subject"],
      received_at: current_version["dateVaReceivedDocument"],
      source: current_version["contentSource"],
      mime_type: system_data["mimeType"],
      alt_doc_types: nil,
      restricted: nil,
      upload_date: system_data["uploadedDateTime"]
    )
  end
end
