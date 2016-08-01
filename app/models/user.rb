class User
  include ActiveModel::Model

  attr_accessor :id, :email, :name, :roles, :station_id, :ip_address

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
      return nil if session["user"].nil?

      User.new(session["user"].merge(ip_address: request.remote_ip))
    end

    def from_css_auth_hash(auth_hash)
      raw_css_response = auth_hash.extra.raw_info
      first_name = raw_css_response["http://vba.va.gov/css/common/fName"]
      last_name = raw_css_response["http://vba.va.gov/css/common/lName"]

      User.new(
        id: auth_hash.uid,
        email: raw_css_response["http://vba.va.gov/css/common/emailAddress"],
        name: "#{first_name} #{last_name}",
        roles: raw_css_response.attributes["http://vba.va.gov/css/caseflow/role"],
        station_id: raw_css_response["http://vba.va.gov/css/common/stationId"]
      )
    end
  end
end
