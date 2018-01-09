class Serializers::V1::DocumentSerializer < ActiveModel::Serializer
  type :document

  attribute :document_id
  attribute :type_id
  attribute :received_at
end
