# Represents a veteran with values fetched from BGS
class Veteran
  include ActiveModel::Model

  BGS_ATTRIBUTES = [:file_number, :first_name, :last_name, :last_four_ssn].freeze

  attr_accessor(*BGS_ATTRIBUTES)
  attr_accessor :file_number
  attr_accessor :user # for authorization

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

  def authorizer
    @authorizer ||= UserAuthorizer.new(user: user, file_number: file_number)
  end

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
    return bgs.fetch_veteran_info(file_number) unless user

    if authorizer.can_read_efolder? && authorizer.veteran_record_found?
      # use .system_veteran_record in case we are POA and .veteran_record is nil
      authorizer.system_veteran_record
    else
      raise BGS::ShareError, "Cannot access Veteran record"
    end
  end
end
