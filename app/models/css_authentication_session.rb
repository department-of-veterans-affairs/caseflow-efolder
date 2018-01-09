class CssAuthenticationSession
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_accessor :id, :name, :roles, :station_id
  attr_reader :css_id, :email

  def email=(value)
    @email = value&.strip
  end

  def css_id=(value)
    @css_id = value&.upcase
  end

  def attributes
    instance_values
  end

  class << self
    def from_css_auth_hash(auth_hash)
      raw_css_response = auth_hash.extra.raw_info
      first_name = raw_css_response["http://vba.va.gov/css/common/fName"]
      last_name = raw_css_response["http://vba.va.gov/css/common/lName"]

      new(id: auth_hash.uid,
          css_id: auth_hash.uid,
          email: raw_css_response["http://vba.va.gov/css/common/emailAddress"],
          name: "#{first_name} #{last_name}",
          roles: raw_css_response.attributes["http://vba.va.gov/css/caseflow/role"],
          station_id: raw_css_response["http://vba.va.gov/css/common/stationId"])
    end
  end
end
