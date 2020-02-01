class CssAuthenticationSession
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_accessor :id, :name, :roles, :station_id, :first_name, :last_name
  attr_reader :css_id, :email

  class BadCssAuthorization < StandardError; end

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
          first_name: first_name,
          last_name: last_name,
          name: "#{first_name} #{last_name}",
          roles: raw_css_response.attributes["http://vba.va.gov/css/caseflow/role"],
          station_id: raw_css_response["http://vba.va.gov/css/common/stationId"])
    end

    def from_iam_auth_hash(auth_hash)
      saml_attributes = auth_hash.extra.raw_info

      # under this IdP, the auth_hash.uid value is the email, but we need the username
      username = saml_attributes["adSamAccountName"]
      user_info = BGSService.new.fetch_user_info(username)

      fail BadCssAuthorization, "Missing CSS info for #{username}" unless user_info[:css_id]

      new(user_info.merge(id: username, name: "#{user_info[:first_name]} #{user_info[:last_name]}"))
    end
  end
end
