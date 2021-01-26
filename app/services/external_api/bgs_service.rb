# frozen_string_literal: true

require "bgs"
require "bgs_errors"

# Thin interface to all things BGS
class ExternalApi::BGSService
  include POAMapper

  attr_reader :client

  class << self
    def current_user
      RequestStore[:current_user]
    end

    def init_client(username: current_user.css_id, station_id: current_user.station_id)
      forward_proxy_url = FeatureToggle.enabled?(:bgs_forward_proxy) ? ENV["RUBY_BGS_PROXY_BASE_URL"] : nil

      # We hardcode the ip since all clients show up as a single IP anyway.
      BGS::Services.new(
        env: Rails.application.config.bgs_environment,
        application: "CASEFLOW",
        client_ip: "10.236.66.133",
        client_station_id: station_id,
        client_username: username,
        ssl_cert_key_file: ENV["BGS_KEY_LOCATION"],
        ssl_cert_file: ENV["BGS_CERT_LOCATION"],
        ssl_ca_cert: ENV["BGS_CA_CERT_LOCATION"],
        forward_proxy_url: forward_proxy_url,
        jumpbox_url: ENV["RUBY_BGS_JUMPBOX_URL"],
        log: true
      )
    end
  end

  def initialize(client: nil)
    @client = client || self.class.init_client
  end

  def parse_veteran_info(veteran_data)
    ssn = veteran_data[:ssn] ? veteran_data[:ssn] : veteran_data[:soc_sec_number]
    last_four_ssn = ssn ? ssn[ssn.length - 4..ssn.length] : nil
    file_number = veteran_data[:file_number].present? ? veteran_data[:file_number] : veteran_data[:claim_number]
    {
      "file_number" => file_number,
      "veteran_first_name" => veteran_data[:first_name],
      "veteran_last_name" => veteran_data[:last_name],
      "veteran_last_four_ssn" => last_four_ssn,
      participant_id: veteran_data[:ptcpnt_id], # key is symbol not string
      deceased: veteran_data[:date_of_death].present?,
      "return_message" => veteran_data[:return_message]
    }
  end

  def fetch_veteran_info(file_number, parsed: true)
    veteran_data = Rails.cache.fetch(fetch_veteran_info_cache_key(file_number), expires_in: 10.minutes) do
      MetricsService.record("BGS: fetch veteran info for vbms id: #{file_number}",
                            service: :bgs,
                            name: "veteran.find_by_file_number") do
        client.veteran.find_by_file_number(file_number)
      end
    end
    return veteran_data unless parsed

    parse_veteran_info(veteran_data) if veteran_data
  end

  # For Claimant POA by file number
  def fetch_poa_by_file_number(file_number)
    bgs_poa = MetricsService.record("BGS: fetch poa for file number: #{file_number}",
                                    service: :bgs,
                                    name: "claimants.find_poa_by_file_number") do
      client.claimants.find_poa_by_file_number(file_number)
    end
    get_claimant_poa_from_bgs_claimants_poa(bgs_poa)
  end

  # For Claimant POA by PID
  def fetch_poa_by_participant_id(participant_id)
    bgs_poa = MetricsService.record("BGS: fetch poa for participant id: #{participant_id}",
                                    service: :bgs,
                                    name: "claimants.find_poa_by_participant_id") do
      client.claimants.find_poa_by_participant_id(participant_id)
    end
    get_claimant_poa_from_bgs_claimants_poa(bgs_poa)
  end

  # Fetch the POA User's org record
  def fetch_poa_org_record(participant_id)
    bgs_poas = MetricsService.record("BGS: fetch record for POA participant id: #{participant_id}",
                                     service: :bgs,
                                     name: "org.find_poas_by_ptcpnt_id") do
      client.org.find_poas_by_ptcpnt_id(participant_id)
    end
    [bgs_poas].flatten.compact.map { |poa| get_poa_from_bgs_org_poa(poa) }
  end

  # The participant IDs here are for Claimants.
  # I.e. returns the list of POAs that represent the Claimants.
  def fetch_poas_by_participant_ids(participant_ids)
    bgs_poas = MetricsService.record("BGS: fetch poas for participant ids: #{participant_ids}",
                                     service: :bgs,
                                     name: "org.find_poas_by_participant_ids") do
      client.org.find_poas_by_ptcpnt_ids(participant_ids)
    end

    # Avoid passing nil
    get_hash_of_poa_from_bgs_poas(bgs_poas || [])
  end

  def fetch_claims_for_file_number(file_number)
    bgs_info = MetricsService.record("BGS: fetch claims by file number: #{file_number}",
                                     service: :bgs,
                                     name: "benefit_claims.find_claim_by_file_number") do
      client.benefit_claims.find_claim_by_file_number(file_number)
    end

    bgs_info
  end

  def fetch_person_info(participant_id)
    bgs_info = MetricsService.record("BGS: fetch person info by participant id: #{participant_id}",
                                     service: :bgs,
                                     name: "people.find_person_by_ptcpnt_id") do
      client.people.find_person_by_ptcpnt_id(participant_id)
    end

    return {} unless bgs_info

    parse_person_info(bgs_info)
  end

  def fetch_person_by_ssn(ssn)
    bgs_info = MetricsService.record("BGS: fetch person by ssn: #{ssn}",
                                     service: :bgs,
                                     name: "people.find_by_ssn") do
      client.people.find_by_ssn(ssn)
    end

    return {} unless bgs_info

    parse_person_info(bgs_info)
  end

  def parse_person_info(bgs_info)
    {
      first_name: bgs_info[:first_nm],
      last_name: bgs_info[:last_nm],
      middle_name: bgs_info[:middle_nm],
      name_suffix: bgs_info[:suffix_nm],
      birth_date: bgs_info[:brthdy_dt],
      email_address: bgs_info[:email_addr],
      file_number: bgs_info[:file_nbr]
    }
  end

  def check_sensitivity(file_number)
    MetricsService.record("BGS: can_access? (find_by_file_number): #{file_number}",
                          service: :bgs,
                          name: "can_access?") do
      client.can_access?(file_number, true)
    end
  end

  def valid_file_number?(file_number)
    number = (file_number || "").strip
    return true if /^\d+$/ =~ number && number.length >= 8 && number.length <= 9
    false
  end

  def record_found?(veteran_info)
    return false unless veteran_info && veteran_info["return_message"]

    # sometimes a reality check is needed on data, regardless of return_message
    return false unless veteran_info["file_number"].present? || veteran_info["veteran_last_four_ssn"].present?

    veteran_info["return_message"].include?("No BIRLS record found") ? false : true
  end

  # if we want to use IAM PIV authn but fake the CSS authz
  def iam_fake_authz(username, station_id)
    # UAT convention is to append the station_id as part of the username
    username_parts = username.match(/^(CF_[a-z]+|CASEFLOW)_(\d+)$/i)
    station_id ||= username_parts[2]
    {
      css_id: username,
      station_id: station_id,
      first_name: 'FAKE',
      last_name: username,
      email: username,
      roles: ["Download eFolder", "System Admin", "Establish Claim", "Mail Intake"] # yes, all of them
    }
  end

  def fetch_user_info(username, station_id = nil, application = "CASEFLOW")
    return iam_fake_authz(username, station_id) if !Rails.deploy_env?(:prod) && FeatureToggle.enabled?(:use_ssoi_iam_fake_authz)

    # always use system user for initial request
    station_client = self.class.init_client(username: User.system_user.css_id, station_id: User.system_user.station_id)
    resp = station_client.common_security.get_css_user_stations(username)
    # example
    # {:network_login_name=>"CF_Q_283", :user_application=>"CASEFLOW", :user_stations=>{:enabled=>true, :id=>"283", :name=>"Hines SDC", :role=>"User"}}
    css_id = resp[:network_login_name] # probably the same as username but just in case.
    stations = Array.wrap(resp[:user_stations]).select { |station| station[:enabled] }

    fail BGS::NoActiveStations unless stations.any?

    fail BGS::StationAssertionRequired if stations.size > 1 && station_id.blank?

    fail BGS::InvalidStation if station_id.present? && !stations.map { |station| station[:id] }.include?(station_id)

    station_id = stations.first[:id] if station_id.blank? # treat "" like nil
    application ||= resp[:user_application]
    profile = client.common_security.get_security_profile(username: css_id, station_id: station_id, application: application)

    # example
    # {:appl_role=>"User", :bdn_num=>"1002", :email_address=>"caseflow@example.com",
    #  :file_num=>nil, :first_name=>"TEST", :functions=>[
    #     {:assigned_value=>"NO", :disable_ind=>"N", :name=>"Download eFolder"},
    #     {:assigned_value=>"NO", :disable_ind=>"N", :name=>"System Admin"}
    #  ],
    #  :job_title=>"Example Review Officer", :last_name=>"ONE", :message=>"Success", :middle_name=>nil, :participant_id=>"123"
    # }
    {
      sensitivity_level: profile[:sec_level],
      participant_id: profile[:participant_id],
      css_id: css_id,
      station_id: station_id,
      first_name: profile[:first_name]&.strip,
      last_name: profile[:last_name]&.strip,
      email: profile[:email_address]&.strip,
      roles: Array.wrap(profile[:functions]).select { |func| func[:assigned_value] == "YES" }.map { |func| func[:name] }
    }
  rescue BGS::ShareError => error
    fail BGS::InvalidUsername if error.message =~ /Unable to get user authroization/
    fail BGS::InvalidStation if error.message =~ /is invalid station number/
    fail BGS::InvalidApplication if error.message =~ /Application Does Not Exist/
    fail BGS::NoCaseflowAccess if error.message =~ /TODO unknown error string/
    {}
  end

  def bust_fetch_veteran_info_cache(file_number)
    Rails.cache.delete(fetch_veteran_info_cache_key(file_number))
  end

  private

  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  # >> >> >> READ BEFORE MODIFYING << << <<
  # ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  # The veteran info cache key **must** be **unique per user**. DO NOT use the
  # `RequestStore[:current_user]` as a part of the cache key because it is
  # not guaranteed that the `RequestStore[:current_user]` is making the request
  # to BGS. Make sure you understand the nuance of this because it can lead to
  # permission issues that can cause data leakages.
  #
  # See: https://github.com/department-of-veterans-affairs/caseflow/issues/15829
  def fetch_veteran_info_cache_key(file_number)
    "bgs_veteran_info_#{client.client_username}_#{client.client_station_id}_#{file_number}"
  end
end
