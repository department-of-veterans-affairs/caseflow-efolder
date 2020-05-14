require 'bgs_errors'

class Fakes::BGSService
  include ActiveModel::Model

  attr_accessor :client

  class << self
    def init_client(username: true, station_id: true)
      OpenStruct.new(css_id: username, station_id: station_id)
    end
  end

  def initialize(client: nil)
    @client = client || self.class.init_client
  end

  def fetch_user_info(username, station_id = nil)
    fail "Must define current_user" unless RequestStore[:current_user] # mock what real service requires

    return {} if username == "error"

    if username == "multiple-stations"
      fail StationAssertionRequired unless station_id.present?
      return multiple_stations_user
    end

    fail BGS::NoActiveStations if username == "zero-stations"
    fail BGS::InvalidStation if station_id == "invalid"
    fail BGS::InvalidUsername if username == "invalid"
    fail BGS::NoCaseflowAccess if station_id == "noaccess"

    {
      css_id: "BVALASTFIRST",
      station_id: station_id.present? ? station_id : "101",
      first_name: "First",
      last_name: "Last",
      email: "first.last@test.gov",
      roles: ["Download eFolder", "Establish Claim"]
    }
  end

  def multiple_stations_user
    {
      css_id: "BVADOEJANE",
      stations: [
        {
          id: "101",
          first_name: "Jane",
          last_name: "Doe",
          email: "jane.doe@example.com",
          roles: ["Download eFolder", "Establish Claim"]
        },
        {
          id: "123",
          first_name: "Jane",
          last_name: "Doe",
          email: "jane.doe@example.com",
          roles: ["VSO"]
        }
      ]
    }
  end

  def demo?(file_number)
    !!(file_number =~ /^DEMO/)
  end

  def not_found?(file_number)
    !!(file_number =~ /^404/)
  end

  def demo_veteran_info(file_number)
    [
      {
        "file_number" => file_number,
        "veteran_first_name" => "Joe",
        "veteran_last_name" => "Snuffy",
        "veteran_last_four_ssn" => "1234",
        "return_message" => "BPNQ0301",
      },
      {
        "file_number" => file_number,
        "veteran_first_name" => "Bob",
        "veteran_last_name" => "Marley",
        "veteran_last_four_ssn" => "3232",
        "return_message" => "BPNQ0301",
      },
      {
        "file_number" => file_number,
        "veteran_first_name" => "James",
        "veteran_last_name" => "Ross",
        "veteran_last_four_ssn" => "4221",
        "return_message" => "BPNQ0301",
      }
    ].sample
  end

  def fetch_veteran_info(file_number, parsed: true)
    return demo_veteran_info(file_number) if demo?(file_number)
    (veteran_info || {})[file_number]
  end

  def parse_veteran_info(veteran_data)
    # call through with dummy client
    ExternalApi::BGSService.new(client: true).parse_veteran_info(veteran_data)
  end

  def valid_file_number?(file_number)
    return true if demo?(file_number.strip)
    return true if not_found?(file_number.strip)
  end

  def check_sensitivity(file_number)
    !(sensitive_files || {})[file_number]
  end

  def record_found?(veteran_info)
    # call through with dummy client
    ExternalApi::BGSService.new(client: true).record_found?(veteran_info)
  end

  # Methods to be stubbed out in tests:
  def veteran_info; end

  def sensitive_files; end

  def fetch_person_info(pid); end

  def fetch_person_by_ssn(ssn); end

  def fetch_poa_by_file_number(fn); end

  def fetch_poas_by_participant_ids(pids); end

  def fetch_poa_by_participant_id(pid); end

  def fetch_claims_for_file_number(fn); end

  def fetch_poa_user_record(pid); end
end
