class Manifest < ActiveRecord::Base
  has_many :sources, class_name: "ManifestSource"
  has_many :user_manifests
  has_many :records, through: :sources

  validates :file_number, presence: true, uniqueness: true

  def start!
    # TODO: create UserManifest object
    # TODO: can we do it in parallel
    vbms_source.start!
    vva_source.start!
  end

  def vbms_source
    sources.find_or_create_by(source: "VBMS")
  end

  def vva_source
    sources.find_or_create_by(source: "VVA")
  end

  # If we do not yet have the veteran_first_name saved in Caseflow's DB, then
  # we want to fetch it from BGS, save it to the DB, then return it
  # TODO: these 3 methods are identical, let's simplify this
  def veteran_first_name
    super || begin
      update_attributes(veteran_first_name: veteran.first_name || "") if veteran
      super
    end
  end

  def veteran_last_name
    super || begin
      update_attributes(veteran_last_name: veteran.last_name || "") if veteran
      super
    end
  end

  def veteran_last_four_ssn
    super || begin
      update_attributes(veteran_last_four_ssn: veteran.last_four_ssn || "") if veteran
      super
    end
  end

  private

  def veteran
    @veteran ||= Veteran.new(file_number: file_number).load_bgs_record!
  end
end
