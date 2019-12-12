require "omniauth/strategies/developer"
require "omniauth/form"

class EfolderAuthForm < OmniAuth::Form
  def header(title, header_info)
    @html << <<-HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
      <title>#{title}</title>
      #{css}
      #{header_info}
    </head>
    <body>
    <h1>#{title}</h1>
    <form method='post' #{"action='#{options[:url]}' " if options[:url]}noValidate='noValidate'>
    HTML
    self
  end
end

class OmniAuth::Strategies::TestAuthStrategy < OmniAuth::Strategies::Developer
  # custom form rendering
  def request_phase
    form = EfolderAuthForm.new(title: "Test VA Saml", url: callback_path)
    options.fields.each do |field|
      form.text_field field.to_s.capitalize.tr("_", " "), field.to_s
    end
    form.button "Sign In"
    form.to_response
  end

  def auth_hash
    hash = super
    hash.uid = hash["info"]["css_id"]
    hash.extra = OmniAuth::AuthHash.new(raw_info: OneLogin::RubySaml::Attributes.new(
      "http://vba.va.gov/css/common/emailAddress" => ["test@test.gov"],
      "http://vba.va.gov/css/common/fName" => ["First"],
      "http://vba.va.gov/css/common/lName" => ["Last"],
      "http://vba.va.gov/css/caseflow/role" => ["Download eFolder", "System Admin"],
      "http://vba.va.gov/css/common/stationId" => [hash["info"]["station_id"]]
    ))
    hash
  end

  option :fields, [:css_id, :station_id]
end
