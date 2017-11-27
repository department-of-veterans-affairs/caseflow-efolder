class Record < ActiveRecord::Base
  belongs_to :manifest_source

  validates :manifest_source, :external_document_id, presence: true
  validates :external_document_id, uniqueness: true
end
