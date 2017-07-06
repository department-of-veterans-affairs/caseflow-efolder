class Serializers::V1::DownloadSerializer < ActiveModel::Serializer
  type :file
  
  has_many :documents, serializer: Serializers::V1::DocumentSerializer
  attribute :manifest_fetched_at
end
