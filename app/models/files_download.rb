class FilesDownload < ApplicationRecord
  belongs_to :user
  belongs_to :manifest

  has_many :sources, through: :manifest
  has_many :records, through: :manifest

  validates :manifest, :user, presence: true

  class << self
    def find_with_manifest(manifest_id:, user_id:)
      includes(:manifest, :sources, :records).find_by(manifest_id: manifest_id, user_id: user_id)
    end
  end

  def start!
    update(requested_zip_at: Time.zone.now)
    manifest.download_and_package_files!
  end
end
