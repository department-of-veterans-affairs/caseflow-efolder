# frozen_string_literal: true

class User < ActiveRecord::Base
  has_many :searches
  has_many :downloads
  # v2 relationship
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

      sesh = CssAuthenticationSession.new(session["user"])
      return nil unless sesh.css_id && sesh.station_id

      find_or_create_by(css_id: sesh.css_id, station_id: sesh.station_id).tap do |u|
        u.name = sesh.name
        u.email = sesh.email
        u.roles = sesh.roles
        u.ip_address = request.remote_ip
        u.save
      end
    end

    def from_api_authenticated_values(css_id:, station_id:)
      sesh = CssAuthenticationSession.new(css_id: css_id, station_id: station_id)
      find_or_create_by(css_id: sesh.css_id, station_id: sesh.station_id)
    end
  end
end
