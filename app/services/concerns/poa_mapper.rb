module POAMapper
  extend ActiveSupport::Concern

  # used by fetch_poas_by_participant_ids (for Claimants)
  # and fetch_poa_by_file_number
  def get_claimant_poa_from_bgs_poa(bgs_record = {})
    return {} unless bgs_record.dig(:power_of_attorney)

    bgs_rep = bgs_record[:power_of_attorney]
    {
      representative_type: bgs_rep[:org_type_nm],
      representative_name: bgs_rep[:nm],
      # Used to find the POA address
      participant_id: bgs_rep[:ptcpnt_id],
      # pass through other attrs
      authzn_change_clmant_addrs_ind: bgs_rep[:authzn_change_clmant_addrs_ind],
      authzn_poa_access_ind: bgs_rep[:authzn_poa_access_ind],
      legacy_poa_cd: bgs_rep[:legacy_poa_cd],
      file_number: bgs_record[:file_number],
      claimant_participant_id: bgs_record[:ptcpnt_id]
    }
  end

  def get_hash_of_poa_from_bgs_poas(bgs_resp)
    [bgs_resp].flatten.each_with_object({}) do |poa, hsh|
      hsh[poa[:ptcpnt_id]] = get_claimant_poa_from_bgs_poa(poa)
    end
  end
end
