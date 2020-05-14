module POAMapper
  extend ActiveSupport::Concern

  # used by bgs.client.org
  def get_claimant_poa_from_bgs_poa(bgs_record = {})
    bgs_record ||= {}
    return {} unless bgs_record.dig(:power_of_attorney)

    bgs_rep = bgs_record[:power_of_attorney]
    {
      representative_type: bgs_rep[:org_type_nm],
      representative_name: bgs_rep[:nm],
      participant_id: bgs_rep[:ptcpnt_id],
      authzn_change_clmant_addrs_ind: bgs_rep[:authzn_change_clmant_addrs_ind],
      authzn_poa_access_ind: bgs_rep[:authzn_poa_access_ind],
      legacy_poa_cd: bgs_rep[:legacy_poa_cd],
      file_number: bgs_record[:file_number],
      claimant_participant_id: bgs_record[:ptcpnt_id]
    }
  end

  # used by fetch_poa_by_file_number (bgs.client.claimants)
  def get_claimant_poa_from_bgs_claimants_poa(bgs_record = {})
    bgs_record ||= {}
    return {} unless bgs_record.dig(:relationship_name)

    {
      participant_id: bgs_record[:person_org_ptcpnt_id],
      representative_name: bgs_record[:person_org_name],
      representative_type: bgs_record[:person_organization_name],
      authzn_change_clmant_addrs_ind: bgs_record[:authzn_change_clmant_addrs_ind],
      authzn_poa_access_ind: bgs_record[:authzn_poa_access_ind],
      veteran_participant_id: bgs_record[:veteran_ptcpnt_id]
    }
  end

  def get_hash_of_poa_from_bgs_poas(bgs_resp)
    [bgs_resp].flatten.each_with_object({}) do |poa, hsh|
      hsh[poa[:ptcpnt_id]] = get_claimant_poa_from_bgs_poa(poa)
    end
  end

  # used by fetch_poa_user_record (bgs.client.org)
  def get_poa_from_bgs_poa(bgs_rep = {})
    return {} unless bgs_rep&.dig(:org_type_nm)

    {
      representative_type: bgs_rep[:org_type_nm],
      representative_name: bgs_rep[:nm],
      participant_id: bgs_rep[:ptcpnt_id]
    }
  end
end
