# frozen_string_literal: true
class User < ActiveRecord::Base
  has_many :searches
  has_many :downloads
  # v2 relationship
  has_many :user_manifests
  has_many :manifests, through: :user_manifests

  before_save { |u| u.email.try(:strip!) }

  NO_EMAIL = "No Email Recorded".freeze

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

  class << self
    def from_session(session, request)
      return nil unless session["user"]
      user = session["user"]
      find_or_create_by(css_id: user["css_id"], station_id: user["station_id"]).tap do |u|
        u.name = user["name"]
        u.email = user["email"]
        u.roles = user["roles"]
        u.ip_address = request.remote_ip
        u.save
      end
    end

    def from_css_auth_hash(auth_hash)
      raw_css_response = auth_hash.extra.raw_info
      first_name = raw_css_response["http://vba.va.gov/css/common/fName"]
      last_name = raw_css_response["http://vba.va.gov/css/common/lName"]

      {
        id: auth_hash.uid,
        css_id: auth_hash.uid,
        email: raw_css_response["http://vba.va.gov/css/common/emailAddress"],
        name: "#{first_name} #{last_name}",
        roles: raw_css_response.attributes["http://vba.va.gov/css/caseflow/role"],
        station_id: raw_css_response["http://vba.va.gov/css/common/stationId"]
      }
    end
  end
end
