class Serializers::V2::ManifestSerializer < ActiveModel::Serializer
  type :manifest

  attribute :veteran_first_name
  attribute :veteran_last_name
  attribute :file_number
  attribute :created_at
  attribute :updated_at
  attribute :fetched_files_at
  attribute :fetched_files_status
  attribute :number_successful_documents
  attribute :number_failed_documents
  attribute :zip_expiration_date
  attribute :time_to_complete
  attribute :seconds_left

  attribute :sources do
    object.sources.map do |source|
      {
        source: source.name,
        status: source.status,
        fetched_at: source.fetched_at,
        number_of_documents: source.records.size
      }
    end
  end

  attribute :records do
    object.records.map do |document|
      {
        id: document.id,
        type_id: document.type_id,
        type_description: document.type_description,
        received_at: document.received_at,
        upload_date: document.upload_date,
        version_id: document.version_id,
        source: document.manifest_source.name,
        status: document.status,
        series_id: document.series_id,
        created_at: document.created_at,
        updated_at: document.updated_at
      }
    end
  end
end
