require 'sinatra/base'
require 'saml_idp/controller'
require 'saml_idp/logout_request_builder'

class FakeSamlIdp < Sinatra::Base
  include SamlIdp::Controller

  post '/api/service_provider' do
    authorize do
      content_type :json
      { status: 'thanks' }.to_json
    end
  end

  get '/saml2sso' do
    build_configs
    validate_saml_request
    encode_response(user)
  end

  get '/saml/logout' do
    build_configs
    if params[:SAMLRequest]
      validate_saml_request
      encode_response(user)
    else
      logout_request_builder.signed
    end
  end

  private

  def head(arg)
    # binding.pry
  end

  def authorize
    if authorization_token == "some-token"
      yield
    else
      status 401
    end
  end

  def authorization_token
    env['HTTP_X_LOGIN_DASHBOARD_TOKEN']
  end

  def logout_request_builder
    session_index = SecureRandom.uuid
    SamlIdp::LogoutRequestBuilder.new(
      session_index,
      SamlIdp.config.base_saml_location,
      'foo/bar/logout',
      user.email,
      OpenSSL::Digest::SHA256
    )
  end

  def build_configs
    SamlIdp.configure do |config|
      idp_base_url = 'http://idp.example.com'

      # for convenience we use the same cert/key pair as the SP
      # but in real-life these would be different.
      # NOTE that x509_certificate is also in config/initializers/omniauth.rb
      # so that the SP can correctly decode our response.
      config.x509_certificate = File.read(Rails.root + "spec/support/saml/idp-example-com.crt")
      config.secret_key = File.read(Rails.root + "spec/support/saml/idp-example-com.key")

      config.base_saml_location = "#{idp_base_url}"
      config.single_service_post_location = "#{idp_base_url}/saml2sso"
      config.single_logout_service_post_location = "#{idp_base_url}/saml/logout"

      config.name_id.formats = {
        email_address: ->(principal) { principal.email }
      }

      saml_format_unspecified = "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified"
      saml_format_email = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"

      config.attributes = {
        email: {
          getter: :email,
          name_format: saml_format_email,
          name_id_format: saml_format_email
        },
        issueInstant: { getter: :issue_instant, name_format: saml_format_unspecified },
        proofingAuth: { getter: :proofing_auth, name_format: saml_format_unspecified },
        assureLevel: { getter: :assure_level, name_format: saml_format_unspecified },
        adSamAccountName: { getter: :ad_sam_account_name, name_format: saml_format_unspecified },
      }

      config.service_provider.finder = lambda do |_issuer_or_entity_id|
        sp_cert = OpenSSL::X509::Certificate.new(config.x509_certificate)
        {
          cert: sp_cert,
          fingerprint: OpenSSL::Digest::SHA1.hexdigest(sp_cert.to_der),
          private_key: config.secret_key,
          assertion_consumer_logout_service_url: 'http://www.example.com/auth/logout',
        }
      end
    end
  end

  def user_attrs
    {
      issue_instant: Time.zone.now.iso8601,
      proofing_auth: "VA-PIV",
      assure_level: "3",
      ad_sam_account_name: "THE_CSS_ID",
      transaction_id: SecureRandom.uuid,
      ad_upn: "some.body@va.gov",
      ad_email: "some.body@va.gov",
      first_name: "Some",
      last_name: "Body",
      role: "some role"
    }
  end

  def user
    if saml_request&.name_id
      OpenStruct.new(user_attrs.merge(email: "nameid@example.com"))
    else
      OpenStruct.new(user_attrs.merge(email: "other@example.com"))
    end
  end
end
