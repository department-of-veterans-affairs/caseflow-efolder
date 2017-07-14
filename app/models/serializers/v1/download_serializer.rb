class Serializers::V1::DownloadSerializer < ActiveModel::Serializer
  type :file

  attribute :manifest_fetched_at

  attribute :documents do
    object.documents.map do |document|
      {
        document_id: document.document_id,
        type_id: document.type_id,
        received_at: document.received_at
      }
    end
  end
end
