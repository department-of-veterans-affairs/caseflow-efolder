require "bgs"

# Thin interface to all things BGS
class BGSService
  cattr_accessor :user

  def self.demo?(file_number)
    file_number =~ /DEMO/
  end

  def self.fetch_veteran_info(file_number)
    if demo?(file_number)
      return {
        "veteran_first_name" => "Test",
        "veteran_last_name" => "User",
        "veteran_last_four_ssn" => "1224"
      }
    end
    @client ||= init_client
    veteran_data = @client.people.find_by_file_number(file_number)
    {
      "veteran_first_name" => veteran_data[:first_nm],
      "veteran_last_name" => veteran_data[:last_nm],
      "veteran_last_four_ssn" => veteran_data[:ssn_nbr]
    } if veteran_data
  end

  def self.check_sensitivity(file_number)
    @client ||= init_client
    @client.can_access? file_number
  end

  def self.init_client
    BGS::Services.new(
      env: Rails.application.config.bgs_environment,
      application: "CASEFLOW",
      client_ip: user.ip_address,
      client_station_id: user.station_id,
      client_username: user.id,
      ssl_cert_key_file: ENV["BGS_KEY_LOCATION"],
      ssl_cert_file: ENV["BGS_CERT_LOCATION"],
      ssl_ca_cert: ENV["BGS_CA_CERT_LOCATION"],
      log: true
    )
  end
end
