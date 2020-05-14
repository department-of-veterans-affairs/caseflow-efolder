# frozen_string_literal: true

# determine authorization rules for whether a User can view
# an efolder for file number.
#
# The rules for POA for deceased veteran that VBMS uses:
#
# 1. Find if the vet is represented by the POA
# 2. Find if the Vet is deceased
# 3. Pull a list of all claimants for the Vet
# 4. See if the POA represents any of those claimants
# 5. Grant access to the efolder

class UserAuthorizer
  attr_reader :file_number, :user

  def initialize(file_number:, user:)
    @file_number = file_number
    @user = user
  end

  def can_read_efolder?
    # if the User can read the veteran record, we have no problem.
    return true if veteran_record.present?

    # if the User can not read the veteran record due to sensitivity, abort.
    return false if sensitive_file

    # if the User can not read the veteran record directly,
    # check for POA rules like VBMS does.
    return true if poa_denied && (veteran_poa? || claimant_poa?)

    # default is no entry.
    false
  end

  def sensitive_file?
    sensitive_file
  end

  def veteran_record_poa_denied?
    poa_denied
  end

  def veteran_poa?
    return false if poa_participant_id.blank?

    poa_participant_id.to_s == user.participant_id.to_s
  end

  def claimant_poa?
    return false unless veteran_deceased?

    veteran_claimants.any? do |claim|
      claim[:poa].dig(:participant_id).to_s == user.participant_id.to_s
    end
  end

  def veteran_deceased?
    system_veteran_record.dig(:deceased)
  end

  def veteran_record
    @veteran_record ||= fetch_veteran_record
  end

  def veteran_record_found?
    return false if system_veteran_record.blank?

    bgs.record_found?(system_veteran_record)
  end

  def system_veteran_record
    # if there is a veteran_record, save ourselves a trip to BGS.
    @system_veteran_record ||= veteran_record.present? ? veteran_record : fetch_veteran_record_as_system_user
  end

  private

  attr_accessor :sensitive_file, :poa_denied

  def veteran_claimants
    @veteran_claimants ||= build_veteran_claimants
  end

  def build_veteran_claimants
    Array(bgs.fetch_claims_for_file_number(file_number)).flatten.map do |claim|
      {
        claimant_participant_id: claim[:ptcpnt_clmant_id],
        veteran_participant_id: claim[:ptcpnt_vet_id],
        status: claim[:status_type_nm],
        poa: poa_for_claimant(claim[:ptcpnt_clmant_id])
      }
    end
  end

  def poa_for_claimant(participant_id)
    @poas_for_claimant ||= {}
    @poas_for_claimant[participant_id] ||= bgs.fetch_poa_by_participant_id(participant_id)
  end

  def fetch_veteran_record
    bgs.fetch_veteran_info(file_number)
  rescue StandardError => err
    self.sensitive_file = true if err.message.include?("Sensitive File - Access Violation")
    self.poa_denied = true if err.message.include?("Power of Attorney of Folder is")
    {}
  end

  def fetch_veteran_record_as_system_user
    system_bgs.fetch_veteran_info(file_number)
  rescue StandardError => err
    raise err
  end

  def poa_participant_id
    file_number_poa&.dig(:participant_id)
  end

  def file_number_poa
    @file_number_poa ||= bgs.fetch_poa_by_file_number(file_number)
  end

  def bgs
    @bgs ||= BGSService.new
  end

  def system_bgs
    @system_bgs ||= BGSService.new(
      client: BGSService.init_client(
        username: User.system_user.css_id,
        station_id: User.system_user.station_id
      )
    )
  end
end
