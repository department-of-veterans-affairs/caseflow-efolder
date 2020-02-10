# Represents a veteran with values fetched from BGS
class Veteran
  include ActiveModel::Model

  BGS_ATTRIBUTES = [:file_number, :first_name, :last_name, :last_four_ssn].freeze

  attr_accessor(*BGS_ATTRIBUTES)
  attr_accessor :file_number

  def load_bgs_record!
    set_attrs_from_bgs_record if found?
    self
  end

  def found?
    bgs_record != :not_found
  end

  def bgs_record
    @bgs_record ||= (fetch_bgs_record || :not_found)
  end

  private

  def bgs
    @bgs ||= BGSService.new
  end

  # TODO: mimic what we have in Caseflow
  def set_attrs_from_bgs_record
    self.first_name = bgs_record["veteran_first_name"]
    self.last_name = bgs_record["veteran_last_name"]
    self.last_four_ssn = bgs_record["veteran_last_four_ssn"]
  end

  def fetch_bgs_record
    bgs.fetch_veteran_info(file_number)
  end
end
