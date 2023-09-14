# frozen_string_literal: true

class User < ApplicationRecord
  has_many :files_downloads
  has_many :manifests, through: :files_downloads

  NO_EMAIL = "No Email Recorded"

  attr_accessor :name, :roles, :ip_address

  def display_name
    return "Unknown" if name.nil?

    name
  end

  # We should not use user.can?("System Admin"), but user.admin? instead
  def can?(function)
    return true if admin?
    # Check if user is granted the function
    return true if granted?(function)
    # Check if user is denied the function
    return false if denied?(function)
    # Ignore "System Admin" function from CSUM/CSEM users
    return false if function.include?("System Admin")

    roles ? roles.include?(function) : false
  end

  def admin?
    Functions.granted?("System Admin", css_id)
  end

  def granted?(thing)
    Functions.granted?(thing, css_id)
  end

  def denied?(thing)
    Functions.denied?(thing, css_id)
  end

  def css_record
    @css_record ||= bgs.client.common_security.get_security_profile(
      username: css_id,
      station_id: station_id,
      application: "CASEFLOW"
    )
  end

  def participant_id
    super || css_record[:participant_id]
  end

  def bgs
    @bgs ||= BGSService.new
  end

  # v2 method
  def recent_downloads
    files_downloads.where(requested_zip_at: Manifest::UI_HOURS_UNTIL_EXPIRY.hours.ago..Time.zone.now)
                   .sort_by(&:requested_zip_at)
                   .reverse
                   .map(&:manifest)
  end

  class << self
    def from_session_and_request(session, request)
      return nil unless session["user"]

      # There could be other values in the session that CssAuthenticationSession doesn't accept
      # as attributes so ignore them
      sesh = CssAuthenticationSession.new(
        session["user"].symbolize_keys.slice(:id, :name, :roles, :station_id, :css_id, :email, :participant_id)
      )
      return nil unless sesh.css_id && sesh.station_id

      ee_psql_user_id = session["user"]["ee_psql_user_id"]
      user = where("id = ? or css_id = ?", ee_psql_user_id, sesh.css_id).first_or_initialize(
        station_id: sesh.station_id,
        name: sesh.name,
        email: sesh.email,
        roles: sesh.roles,
        css_id: sesh.css_id,
        ip_address: request.remote_ip,
        participant_id: sesh.participant_id
      )
      user.last_login_at = Time.zone.now
      user.save!

      session["user"]["ee_psql_user_id"] = user.id
      user
    end

    # case-insensitive search
    def find_by_css_id(css_id)
      find_by("UPPER(css_id)=UPPER(?)", css_id)
    end

    def from_api_authenticated_values(css_id:, station_id:)
      sesh = CssAuthenticationSession.new(css_id: css_id, station_id: station_id)
      user = find_by_css_id(sesh.css_id)
      return user if user

      create!(css_id: sesh.css_id.upcase, station_id: sesh.station_id)
    end

    def system_user
      @system_user ||= begin
        private_method_name = "#{Rails.current_env}_system_user".to_sym
        send(private_method_name)
      end
    end

    private

    def prod_system_user
      find_or_initialize_by(station_id: "283", css_id: "CSFLOW")
    end

    alias preprod_system_user prod_system_user

    def uat_system_user
      find_or_initialize_by(station_id: "317", css_id: "CASEFLOW1")
    end

    alias test_system_user uat_system_user
    alias development_system_user uat_system_user
  end
end
