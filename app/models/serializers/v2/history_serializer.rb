class Serializers::V2::HistorySerializer < ActiveModel::Serializer
  type :manifest

  attribute :veteran_first_name
  attribute :veteran_last_name
  attribute :file_number
  attribute :fetched_files_status
  attribute :zip_expiration_date
  attribute :number_failed_documents
end
