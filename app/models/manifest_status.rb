class ManifestStatus < ActiveRecord::Base
  enum status: {
    pending: 0,
    success: 1,
    failed: 2
  }

  belongs_to :manifest

  validates :manifest, :source, presence: true
end
