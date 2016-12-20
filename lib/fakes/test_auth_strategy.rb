require "omniauth/strategies/developer"
require "omniauth/form"

class OmniAuth::Strategies::TestAuthStrategy < OmniAuth::Strategies::Developer
  # custom form rendering
  def request_phase
    form = OmniAuth::Form.new(title: "Test VA Saml", url: callback_path)
    options.fields.each do |field|
      form.text_field field.to_s.capitalize.tr("_", " "), field.to_s
    end
    form.button "Sign In"
    form.to_response
  end

  def auth_hash
    hash = super
    hash.uid = "CSFLOW" + rand(10).to_s
    hash.extra = OmniAuth::AuthHash.new(raw_info: OneLogin::RubySaml::Attributes.new(
      "http://vba.va.gov/css/common/emailAddress" => [hash["info"]["email"]],
      "http://vba.va.gov/css/common/fName" => ["First"],
      "http://vba.va.gov/css/common/lName" => ["Last"],
      "http://vba.va.gov/css/caseflow/role" => ["Download eFolder", "System Admin"],
      "http://vba.va.gov/css/common/stationId" => ["283"]
    ))
    hash
  end

  option :fields, [:email]
end
