require "omniauth/strategies/developer"
require "omniauth/form"

class EfolderAuthForm < OmniAuth::Form
  def hidden_field(name, value)
    @html << "\n<input type='hidden' name='#{name}' value='#{value}' />"
    self
  end

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
    form.hidden_field :username, session["login"]["username"]
    form.hidden_field :station_id, session["login"]["station_id"]
    form.button "Fake PIV Login"
    form.to_response
  end

  def auth_hash
    hash = super
    hash.uid = hash["info"]["css_id"]
    hash
  end
end
