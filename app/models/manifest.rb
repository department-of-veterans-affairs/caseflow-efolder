class Manifest < ActiveRecord::Base
  has_many :manifest_statuses
  has_many :user_manifests
  has_many :records

  validates :file_number, presence: true, uniqueness: true
end
