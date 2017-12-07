class Manifest < ActiveRecord::Base
  has_many :sources, class_name: "ManifestSource"
  has_many :user_manifests
  has_many :records, through: :sources
  has_many :users, through: :user_manifests

  validates :file_number, presence: true, uniqueness: true

  def start!
    vbms_source.start!
    vva_source.start!
  end

  def vbms_source
    sources.find_or_create_by(source: "VBMS")
  end

  def vva_source
    sources.find_or_create_by(source: "VVA")
  end

  # If we do not yet have the veteran info saved in Caseflow's DB, then
  # we want to fetch it from BGS, save it to the DB, then return it
  %w(veteran_first_name veteran_last_name veteran_last_four_ssn).each do |name|
    define_method(name) do
      self[name] || begin
        update_veteran_info
        self[name]
      end
    end
  end

  def downloaded_by?(user)
    users.include?(user)
  end

  def veteran
    @veteran ||= Veteran.new(file_number: file_number).load_bgs_record!
  end

  def self.find_or_create_by_user(user:, file_number:)
    manifest = Manifest.find_or_create_by(file_number: file_number)
    # Create a record every time for auditing purposes
    manifest.user_manifests.create(user: user)
    manifest
  end

  private

  def update_veteran_info
    return unless veteran
    update(veteran_first_name: veteran.first_name || "",
           veteran_last_name: veteran.last_name || "",
           veteran_last_four_ssn: veteran.last_four_ssn || "")
  end
end
