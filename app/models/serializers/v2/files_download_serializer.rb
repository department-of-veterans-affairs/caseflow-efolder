class Serializers::V2::FilesDownloadSerializer < ActiveModel::Serializer
  type :manifest

  attribute :fetched_files_status
  attribute :fetched_files_at
  attribute :number_successful_documents
  attribute :number_failed_documents
  attribute :time_to_complete
  attribute :seconds_left

  attribute :records do
    object.records.map do |document|
      {
        id: document.id,
        type_id: document.type_id,
        status: document.status,
        received_at: document.received_at,
        version_id: document.version_id,
        series_id: document.series_id,
        created_at: document.created_at,
        updated_at: document.updated_at
      }
    end
  end
end
