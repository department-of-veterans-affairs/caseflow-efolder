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
    config.middleware.insert_before 0, "Rack::Cors" do
      allow do
        origins (ENV["CORS_URL"] || "http://localhost:3000")
        resource '*', headers: :any, methods: :any, credentials: true
      end
    end

    config.active_job.queue_adapter = :sidekiq

    config.cache_store = :redis_store, Rails.application.secrets.redis_url_cache, { expires_in: 24.hours }

    config.analytics_account = "UA-74789258-2"
  end
end
