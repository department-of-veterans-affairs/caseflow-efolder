require "bgs"

# Thin interface to all things BGS
class BGSService
  def self.fetch_veteran_name(file_number)
    client ||= init_client
    veteran_data = client.people.find_by_file_number(file_number) || {}

    "#{veteran_data[:first_nm]} #{veteran_data[:last_nm]}"
  end

  def self.init_client
    BGS::Services.new(
     env: "beplinktest",
     application: "CASEFLOW",
     client_ip: "127.0.0.1",
     client_station_id: "283",
     client_username: "CSFLOW",
     log: true,
    )
  end
end