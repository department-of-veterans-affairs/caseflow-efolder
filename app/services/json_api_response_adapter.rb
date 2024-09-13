# frozen_string_literal: true

# Translates JSON API responses into a format that's compatible with the legacy SOAP responses expected
# by most of caseflow-efolder
class JsonApiResponseAdapter
  def adapt_v2_fetch_documents_for(json_response)
    json_response = normalize_json_response(json_response)

    return [] if check_empty_result?(json_response)
    return nil unless valid_file_response?(json_response)

    documents = []
    json_response["files"].each do |file_resp|
      documents.push(v2_fetch_documents_file_response(file_resp))
    end

    documents
  end

  private

  def normalize_json_response(json_response)
    if json_response.blank?
      {}
    elsif json_response.instance_of?(Hash)
      json_response.with_indifferent_access
    elsif json_response.instance_of?(String)
      JSON.parse(json_response)
    end
  end

  def valid_file_response?(json_response)
    json_response.key?("files")
  end

  def check_empty_result?(json_response)
    json_response.key?("page") && json_response['page']['totalResults'].to_i == 0
  end

  def v2_fetch_documents_file_response(file_json)
    system_data = file_json["currentVersion"]["systemData"]
    provider_data = file_json["currentVersion"]["providerData"]

    OpenStruct.new(
      document_id: "{#{file_json['currentVersionUuid'].upcase}}",
      series_id: "{#{file_json['uuid'].upcase}}",
      version: "1",
      type_description: provider_data["subject"],
      type_id: provider_data["documentTypeId"],
      doc_type: provider_data["documentTypeId"],
      subject: provider_data["subject"],
      # gsub here so that JS will correctly handle this date
      # (with dashes the date is 1 day off due to UTC issues)
      received_at: provider_data["dateVaReceivedDocument"]&.gsub("-", "/"),
      source: provider_data["contentSource"],
      mime_type: system_data["mimeType"],
      alt_doc_types: nil,
      restricted: nil,
      upload_date: system_data["uploadedDateTime"]
    )
  end
end
