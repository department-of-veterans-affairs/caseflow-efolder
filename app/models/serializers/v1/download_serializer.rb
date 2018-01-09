# frozen_string_literal: true

class Serializers::V1::DownloadSerializer < ActiveModel::Serializer
  type :file

  attribute :manifest_fetched_at
  attribute :manifest_vva_fetched_at
  attribute :manifest_vbms_fetched_at

  attribute :vbms_error do
    object.status == "vbms_connection_error"
  end

  attribute :vva_error do
    object.status == "vva_connection_error"
  end

  attribute :documents do
    object.documents.order(:id).map do |document|
      {
        id: document.id,
        type_id: document.type_id,
        received_at: document.received_at,
        external_document_id: document.document_id
      }
    end
  end
end
