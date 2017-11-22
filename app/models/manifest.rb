class Manifest < ActiveRecord::Base
  has_many :sources, class_name: "ManifestSource"
  has_many :user_manifests
  has_many :records, through: :sources

  validates :file_number, presence: true, uniqueness: true
end
