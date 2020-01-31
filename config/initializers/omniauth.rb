require 'omniauth/strategies/saml/validation_error'

ENV_SAML_XML = 'SSOI_SAML_XML_LOCATION'
ENV_SAML_KEY = 'SSOI_SAML_PRIVATE_KEY_LOCATION'
ENV_SAML_CRT = 'SSOI_SAML_CERTIFICATE_LOCATION'
ENV_SAML_ID = 'SSOI_SAML_ID'

# we will switch back to the all-SSOI naming once feature toggle is removed.
ENV_IAM_XML = 'IAM_SAML_XML_LOCATION'

Rails.application.config.ssoi_login_path = "/auth/samlva"

def ssoi_authentication_enabled?
  # never disable in production
  return true if Rails.env.production?

  # detect SAML files
  return ENV.has_key?(ENV_SAML_XML) && ENV.has_key?(ENV_SAML_KEY) && ENV.has_key?(ENV_SAML_CRT)
end

def use_ssoi_iam?
  Rails.env.production? && FeatureToggle.enabled?(:use_ssoi_iam)
rescue
  false
end

# :nocov:
if use_ssoi_iam?
  puts "use_sso_iam true"
  # for transition to new IdP. Once fully deployed, we can remove the older ENV vars and certs.
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :samlva,
      "https://efolder.cf.ds.va.gov", # same in all envs # ENV[ENV_SAML_ID],
      ENV[ENV_SAML_KEY],
      ENV[ENV_SAML_CRT],
      ENV[ENV_IAM_XML],
      true,
      callback_path: '/auth/saml_callback',
      path_prefix: '/auth',
      name_identifier_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
      va_iam_provider: :css # TODO
  end
elsif ssoi_authentication_enabled?
  puts "ssoi_authentication_enabled"
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :samlva,
      ENV[ENV_SAML_ID],
      ENV[ENV_SAML_KEY],
      ENV[ENV_SAML_CRT],
      ENV[ENV_SAML_XML],
      true,
      callback_path: '/auth/saml_callback',
      path_prefix: '/auth',
      name_identifier_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
      va_iam_provider: :css
  end
elsif Rails.env.test?
  puts "test"
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :samlva,
      "www.example.com",
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
  puts "fakes/test_auth_strategy"
  require 'fakes/test_auth_strategy'

  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :test_auth_strategy,
      callback_path: '/auth/saml_callback',
      path_prefix: '/auth',
      request_path: Rails.application.config.ssoi_login_path
  end
end
# :nocov:
