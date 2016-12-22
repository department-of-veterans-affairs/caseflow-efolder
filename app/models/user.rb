# frozen_string_literal: true
class User < ActiveRecord::Base
  has_many :searches
  has_many :downloads

  NO_EMAIL = "No Email Recorded".freeze

  attr_accessor :name, :roles, :ip_address

  def display_name
    return "Unknown" if name.nil?
    name
  end

  def can?(thing)
    return false if roles.nil?
    roles.include? thing
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
        css_id: auth_hash.uid,
        email: raw_css_response["http://vba.va.gov/css/common/emailAddress"],
        name: "#{first_name} #{last_name}",
        roles: raw_css_response.attributes["http://vba.va.gov/css/caseflow/role"],
        station_id: raw_css_response["http://vba.va.gov/css/common/stationId"]
      }
    end
  end
end
