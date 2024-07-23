require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.

  # Fall back to the `application.rb` setting for `config.cache_store`, which properly uses the Redis instance we have running in a Docker container.
  # See this commit for historical context: https://github.com/department-of-veterans-affairs/caseflow-efolder/pull/1030/commits/3d8e1061dc8b9e7dca8cb658f3af3a301a070df0
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    # config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    # config.cache_store = :null_store
  end


  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # When `config.assets.debug == true`, there is an edge case where the length of the Link header could become
  # exceptionally long, due to the way concatenated assets are split and included separately, thus exceeding the
  # maximum 8192 bytes for HTTP response headers. To preclude this from happening, we override the default here:
  # Default as of 6.1: true
  config.action_view.preload_links_header = false


#=========================================================================================
# eFolder - Custom Config Settings
# Keep all efolder specific config settings below for clean diff's when upgrading rails
#=========================================================================================
  config.vva_wsdl = "https://vbaphid521ldb.vba.va.gov:7002/VABFI/services/vva?wsdl"

  config.s3_enabled = true
  config.s3_bucket_name = "dsva-appeals-efolder-demo"

  config.api_key = "token"

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.sqs_create_queues = true
  config.sqs_endpoint = 'http://localhost:4566'
end