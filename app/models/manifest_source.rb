class ManifestSource < ActiveRecord::Base
  enum status: {
    pending: 0,
    success: 1,
    failed: 2
  }

  belongs_to :manifest
  has_many :records

  validates :manifest, :source, presence: true
  validates :manifest, uniqueness: { scope: :source }
  validates :source, inclusion: { in: %w(VBMS VVA) }

  def start!
    return if current?
    # TODO: If it is pending, don't make another request
    # https://bibwild.wordpress.com/2013/06/03/activerecord-atomic-check-and-update-through-optimistic-locking/
    V2::DownloadManifestJob.perform_now(self)
    # TODO: start downloading records from VBMS and save to S3
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
    success? && fetched_at && fetched_at > 3.hours.ago
  end
end
