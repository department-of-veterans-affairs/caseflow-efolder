require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CaseflowEfolder
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    #=======================================================================================
    # Rails 5.0 default overrides
    #---------------------------------------------------------------------------------------
    
    # Enable per-form CSRF tokens. Previous versions had false.
    # Deafault as of 5.0: true
    Rails.application.config.action_controller.per_form_csrf_tokens = false

    # Enable origin-checking CSRF mitigation. Previous versions had false.
    # Default as of 5.0: true
    Rails.application.config.action_controller.forgery_protection_origin_check = false

    # Make Ruby 2.4 preserve the timezone of the receiver when calling `to_time`.
    # Previous versions had false.
    # Default as of 5.0: true
    ActiveSupport.to_time_preserves_timezone = false

    # Require `belongs_to` associations by default. Previous versions had false.
    # Default as of 5.0: true
    Rails.application.config.active_record.belongs_to_required_by_default = false   


    #=======================================================================================
    # Rails 5.1 default overrides
    #---------------------------------------------------------------------------------------
    
    # Make `form_with` generate non-remote forms.
    # Default as of 5.1: true
    Rails.application.config.action_view.form_with_generates_remote_forms = false


    #=======================================================================================
    # Rails 5.2 default overrides
    #---------------------------------------------------------------------------------------

    # Use AES-256-GCM authenticated encryption for encrypted cookies.
    # Also, embed cookie expiry in signed or encrypted cookies for increased security.
    #
    # This option is not backwards compatible with earlier Rails versions.
    # It's best enabled when your entire app is migrated and stable on 5.2.
    #
    # Existing cookies will be converted on read then written with the new scheme.
    # Default as of 5.2: true
    Rails.application.config.action_dispatch.use_authenticated_cookie_encryption = false

    # Use AES-256-GCM authenticated encryption as default cipher for encrypting messages
    # instead of AES-256-CBC, when use_authenticated_message_encryption is set to true.
    # Default as of 5.2: true
    Rails.application.config.active_support.use_authenticated_message_encryption = false

    # Add default protection from forgery to ActionController::Base instead of in
    # ApplicationController.
    # Default as of 5.2: true
    Rails.application.config.action_controller.default_protect_from_forgery = false

    # Store boolean values are in sqlite3 databases as 1 and 0 instead of 't' and
    # 'f' after migrating old data.
    # Default as of 5.2: true
    Rails.application.config.active_record.sqlite3.represent_boolean_as_integer = false


    #=======================================================================================
    # eFolder Specific configs
    #---------------------------------------------------------------------------------------
    config.download_filepath = Rails.root + "tmp/files"
    config.autoload_paths += Dir[Rails.root + 'app/jobs']
    config.autoload_paths << Rails.root.join('lib')
    config.autoload_paths << Rails.root.join('lib/scripts')

    # Currently the Caseflow client makes calls to get document content directly
    # from eFolder Express to reduce load on Caseflow. Since Caseflow and eFolder
    # are in different sub-domains, we need to enable CORS.
    cors_origins = ENV["CORS_URL"]

    # Enable localhost CORS for development and test environments and get rid of null values
    # if the environment variable isn't set
    cors_origins ||= "http://localhost:3000" unless Rails.env.production?

    # Load javascript from URL instead of precompiled assets to allow javascript reloading without restarting rails.
    config.react_spa_javascript_url = ENV["JAVASCRIPT_URL"]

    config.middleware.insert_before 0, Rack::Cors do
        allow do
          origins cors_origins
          resource /\/api\/v(1|2)\/.*/,
            headers:     :any, # Headers to allow in the request
            methods:     :get,
            # when making a cross-origin request, only Cache-Control, Content-Language, 
            # Content-Type, Expires, Last-Modified, Pragma are exposed. PDF.js requires some additional headers to be sent as well
            expose:      ['content-range, content-length, accept-ranges, X-Document-Source'], # Headers to send in response
            credentials: true
        end
    end

    config.exceptions_app = self.routes

    config.active_job.queue_adapter = :shoryuken

    # setup the deploy env environment variable
    ENV['DEPLOY_ENV'] ||= Rails.env

    # sqs details
    config.active_job.queue_name_prefix = "efolder_" + ENV['DEPLOY_ENV']

    config.sqs_create_queues = false
    config.sqs_endpoint = nil

    config.cache_store = :redis_store, Rails.application.secrets.redis_url_cache, { expires_in: 24.hours }

    config.analytics_account = "UA-74789258-2"

    config.bgs_environment = ENV["BGS_ENVIRONMENT"] || "beplinktest"
  end
end
