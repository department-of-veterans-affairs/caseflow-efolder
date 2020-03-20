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
    def from_iam_auth_hash(auth_hash, username = nil, station_id = nil)
      saml_attributes = auth_hash.extra.raw_info

      # At this point we are authenticated via PIV but we must still perform
      # the authorization step via BGS common security.
      # We allow for explicit username/station_id to be used for authorization,
      # since (a) a user may have multiple stations and we allow them to assert one,
      # and (b) in non-production environments we allow user to assert a test username.

      # under this IdP, the auth_hash.uid value is the email, but we need the username.
      # in development env, saml_attributes will be nil.
      username = saml_attributes&.[]("adSamAccountName") if username.blank? # treat "" like nil

      # set global object so that BGS service understands "current_user"
      RequestStore[:current_user] = OpenStruct.new(station_id: station_id, css_id: username)

      user_info = BGSService.new.fetch_user_info(username, station_id)

      fail BadCssAuthorization, "Missing CSS info for #{username}" unless user_info[:css_id]

      new(
        id: username,
        css_id: user_info[:css_id],
        email: user_info[:email],
        first_name: user_info[:first_name],
        last_name: user_info[:last_name],
        roles: user_info[:roles],
        station_id: user_info[:station_id],
        name: "#{user_info[:first_name]} #{user_info[:last_name]}",
      )
    end
  end
end
