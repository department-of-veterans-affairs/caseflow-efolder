require_relative 'boot'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CaseflowEfolder
  class Application < Rails::Application
    
    # Initialize configuration defaults for originally generated Rails version.
    # config.load_defaults 5.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.download_filepath = Rails.root + "tmp/files"

    config.autoload_paths += Dir[Rails.root + 'app/jobs']
    config.autoload_paths << Rails.root.join('lib')

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
            expose:      ['content-range, content-length, accept-ranges'], # Headers to send in response
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
