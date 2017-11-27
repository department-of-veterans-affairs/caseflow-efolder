class ManifestSource < ActiveRecord::Base
  enum status: {
    pending: 0,
    success: 1,
    failed: 2
  }

  belongs_to :manifest
  has_many :records

  validates :manifest, :source, presence: true
end
