#

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
    veteran_record[:deceased]
  end

  private

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

  def veteran_record
    @veteran_record ||= bgs.fetch_veteran_info(file_number)
  end

  def poa_participant_id
    file_number_poa.dig(:participant_id)
  end

  def file_number_poa
    @file_number_poa ||= bgs.fetch_poa_by_file_number(file_number)
  end

  def bgs
    @bgs ||= BGSService.new
  end
end
