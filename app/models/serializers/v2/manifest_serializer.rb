class Serializers::V2::ManifestSerializer < ActiveModel::Serializer
  type :manifest

  attribute :veteran_first_name
  attribute :veteran_last_name
  attribute :created_at
  attribute :updated_at

  attribute :sources do
    object.sources.map do |source|
      {
        source: source.source,
        status: source.status,
        fetched_at: source.fetched_at
      }
    end
  end

  attribute :records do
    object.records.order(:id).map do |document|
      {
        id: document.id,
        type_id: document.type_id,
        received_at: document.received_at,
        external_document_id: document.external_document_id
      }
    end
  end
end
