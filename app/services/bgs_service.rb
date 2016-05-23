require "bgs"

# Thin interface to all things BGS
class BGSService
  cattr_accessor :user

  def self.fetch_veteran_name(file_number)
    @client ||= init_client
    veteran_data = @client.people.find_by_file_number(file_number) || {}

    "#{veteran_data[:first_nm]} #{veteran_data[:last_nm]}"
  end

  def self.check_sensitivity(file_number)
    @client ||= init_client
    @client.claimants.get_sensitivity_access(file_number)
  end

  def self.init_client
    BGS::Services.new(
      env: Rails.application.config.bgs_environment,
      application: "CASEFLOW",
      client_ip: user.ip_address,
      client_station_id: user.station_id,
      client_username: user.id,
      log: true
    )
  end
end
