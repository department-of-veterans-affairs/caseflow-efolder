class Record < ActiveRecord::Base
  belongs_to :manifest

  validates :manifest, :external_document_id, presence: true
  validates :external_document_id, uniqueness: true
end
