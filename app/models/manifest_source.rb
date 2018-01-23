class ManifestSource < ActiveRecord::Base
  enum status: {
    initialized: 0,
    pending: 1,
    success: 2,
    failed: 3
  }

  belongs_to :manifest
  has_many :records, dependent: :destroy

  validates :manifest, :source, presence: true
  validates :manifest, uniqueness: { scope: :source }
  validates :source, inclusion: { in: %w[VBMS VVA] }

  delegate :file_number, to: :manifest

  def start!
    return if current? || pending?
    update(status: :pending)
    V2::DownloadManifestJob.perform_later(self)
  end

  def service
    case source
    when "VBMS"
      VBMSService
    when "VVA"
      VVAService
    end
  end

  private

  def current?
    # TODO: expiration duration is going to be determined whether it is UI or Reader API
    success? && fetched_at && fetched_at > 3.hours.ago
  end
end
