require File.expand_path('../boot', __FILE__)
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CaseflowEfolder
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    config.download_filepath = Rails.root + "tmp/files"

    config.autoload_paths += Dir[Rails.root + 'app/jobs']
    config.autoload_paths << Rails.root.join('lib')

    # Currently the Caseflow client makes calls to get document content directly
    # from eFolder Express to reduce load on Caseflow. Since Caseflow and eFolder
    # are in different sub-domains, we need to enable CORS.
    cors_origins = ENV["CORS_URL"] || "" # Default to empty string to allow rake jobs to execute

    # Enable localhost CORS for development and test environments and get rid of null values
    # if the environment variable isn't set
    cors_origins = "http://localhost:3000" if !Rails.env.production? && cors_origins.empty?

    config.middleware.insert_before 0, "Rack::Cors" do
        allow do
          origins cors_origins
          resource '/api/v1/*',
            headers:     :any, # Headers to allow in the request
            methods:     :get,
            # when making a cross-origin request, only Cache-Control, Content-Language, 
            # Content-Type, Expires, Last-Modified, Pragma are exposed. PDF.js requires some additional headers to be sent as well
            expose:      ['content-range, content-length, accept-ranges'], # Headers to send in response
            credentials: true
        end
    end

    config.active_job.queue_adapter = :sidekiq

    config.cache_store = :redis_store, Rails.application.secrets.redis_url_cache, { expires_in: 24.hours }

    config.analytics_account = "UA-74789258-2"
  end
end
