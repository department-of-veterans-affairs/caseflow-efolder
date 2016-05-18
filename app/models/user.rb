class User
  include ActiveModel::Model

  attr_accessor :email, :name, :roles, :station

  def display_name
    return "Unknown" if name.nil?
    name
  end

  def can?(thing)
    return false if roles.nil?
    roles.include? thing
  end

  class << self
    def from_css_auth_hash(auth_hash)
      raw_css_response = auth_hash.extra.raw_info
      first_name = raw_css_response["http://vba.va.gov/css/common/fName"]
      last_name = raw_css_response["http://vba.va.gov/css/common/lName"]
      User.new(
        email: raw_css_response["http://vba.va.gov/css/common/emailAddress"],
        name: "#{first_name} #{last_name}",
        roles: raw_css_response.attributes["http://vba.va.gov/css/caseflow/role"],
        station: raw_css_response["http://vba.va.gov/css/common/stationId"]
      )
    end
  end
end
