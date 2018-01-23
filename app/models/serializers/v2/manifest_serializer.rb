class Serializers::V2::ManifestSerializer < ActiveModel::Serializer
  type :manifest

  attribute :veteran_first_name
  attribute :veteran_last_name
  attribute :created_at
  attribute :updated_at

  attribute :sources do
    object.sources.map do |source|
      {
        source: source.name,
        status: source.status,
        fetched_at: source.fetched_at,
        number_of_documents: source.records.count
      }
    end
  end

  attribute :records do
    object.records.map do |document|
      {
        id: document.id,
        type_id: document.type_id,
        received_at: document.received_at,
        version_id: document.version_id,
        series_id: document.series_id,
        created_at: document.created_at,
        updated_at: document.updated_at
      }
    end
  end
end
