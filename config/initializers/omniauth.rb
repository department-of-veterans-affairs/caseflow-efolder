require 'omniauth/strategies/saml/validation_error'

ENV_SAML_KEY = 'SSOI_SAML_PRIVATE_KEY_LOCATION'
ENV_SAML_CRT = 'SSOI_SAML_CERTIFICATE_LOCATION'
ENV_SAML_ID = 'SSOI_SAML_ID'
ENV_IAM_XML = 'IAM_SAML_XML_LOCATION'

Rails.application.config.ssoi_login_path = "/auth/samlva"

def ssoi_authentication_enabled?
  # never disable in production
  return true if Rails.env.production?

  # detect SAML files
  return ENV.has_key?(ENV_IAM_XML) && ENV.has_key?(ENV_SAML_KEY) && ENV.has_key?(ENV_SAML_CRT) && ENV.has_key?(ENV_SAML_ID)
end

# :nocov:
if ssoi_authentication_enabled?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :samlva,
      Rails.deploy_env?(:prodtest) ? ENV[ENV_SAML_ID] : "https://efolder.cf.ds.va.gov",
      ENV[ENV_SAML_KEY],
      ENV[ENV_SAML_CRT],
      ENV[ENV_IAM_XML],
      true,
      callback_path: '/auth/saml_callback',
      path_prefix: '/auth',
      name_identifier_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
      va_iam_provider: :css # TODO
  end
elsif Rails.env.test?
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :samlva,
      "efolder.example.com",
      Rails.root + "spec/support/saml/idp-example-com.key",
      Rails.root + "spec/support/saml/idp-example-com.crt",
      Rails.root + "spec/support/saml/test-iam-metadata.xml",
      true,
      callback_path: '/auth/saml_callback',
      path_prefix: '/auth',
      name_identifier_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
      va_iam_provider: :css # TODO
  end
else
  # local development uses 'fake' SAML IdP not the test IdP.
  require 'fakes/test_auth_strategy'

  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :test_auth_strategy,
      callback_path: '/auth/saml_callback',
      path_prefix: '/auth',
      request_path: Rails.application.config.ssoi_login_path
  end
end
# :nocov:
