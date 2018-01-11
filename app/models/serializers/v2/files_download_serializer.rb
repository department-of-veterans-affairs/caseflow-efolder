class Serializers::V2::FilesDownloadSerializer < ActiveModel::Serializer
  type :files_download

  attribute :status
  attribute :fetched_files_at

  attribute :records do
    object.records.map do |document|
      {
        id: document.id,
        type_id: document.type_id,
        status: document.status,
        received_at: document.received_at,
        external_document_id: document.external_document_id,
        created_at: document.created_at,
        updated_at: document.updated_at
      }
    end
  end
end
