# frozen_string_literal: true

source ENV["GEM_SERVER_URL"] || "https://rubygems.org"

gem "caseflow", git: "https://github.com/department-of-veterans-affairs/caseflow-commons", ref: "2970f415ba80ccf338e1b4ecb4386c98be29f8b9"

gem "moment_timezone-rails"

# Use sqlite3 as the database for Active Record
gem "sqlite3", platforms: [:ruby, :mswin, :mingw, :mswin, :x64_mingw]

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "4.2.7.1"

gem "activerecord-jdbcpostgresql-adapter", platforms: :jruby
gem "pg", platforms: :ruby

gem "aws-sdk", "~> 2"

gem "prometheus-client", "~> 0.7.1"

gem "activejob_dj_overrides"

# Use SCSS for stylesheets
gem "sass-rails", "~> 5.0"
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"
# Use CoffeeScript for .coffee assets and views
gem "coffee-rails", "~> 4.1.0"

# Explicitly adding USWDS gem until it's published and we can
# include it via commons
gem "uswds-rails", git: "https://github.com/18F/uswds-rails-gem.git"

# See https://github.com/rails/execjs#readme for more supported runtimes
gem "therubyracer", platforms: :ruby
gem "therubyrhino", platforms: :jruby

# Error reporting to Sentry
gem "sentry-raven"

gem "newrelic_rpm"

gem "dogstatsd-ruby"

# SSOI
gem "omniauth-saml-va", git: "https://github.com/department-of-veterans-affairs/omniauth-saml-va", branch: "paultag/css"

# Required until downstream dependency upgrades omniauth to 1.3.2 or greater.
# https://github.com/omniauth/omniauth-saml/blob/89eeb83517b2333666c4cb627d416cef63ac041d/omniauth-saml.gemspec#L16
gem "omniauth", "~> 1.3.2"

gem "puma"

gem "rack-cors", require: "rack/cors"

# Use jquery as the JavaScript library
gem "jquery-rails"
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem "turbolinks"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.0"
# bundle exec rake doc:rails generates the API under doc/api.
gem "sdoc", "~> 0.4.0", group: :doc

gem "redis-rails", "~> 5.0.2"

gem "sidekiq"
gem "sidekiq-cron", "~> 0.4.0"

gem "rubyzip"

# use to_b method to convert string to boolean
gem "wannabe_bool"

gem "zaru"

gem "active_model_serializers"

gem "redis-namespace"
gem "redis-semaphore"

gem "request_store"

gem "mini_magick"

gem "httpclient"

gem "bgs", git: "https://github.com/department-of-veterans-affairs/ruby-bgs.git", branch: "9266698668bf361bf5df06990d06da59abb7c608"
gem "connect_vbms", git: "https://github.com/department-of-veterans-affairs/connect_vbms.git", ref: "7b3da0fa5ee6732d3c8ad2f557e425e770b1f435"
gem "connect_vva", git: "https://github.com/department-of-veterans-affairs/connect_vva.git", ref: "5af0ad0e2538c1039bce75dbc6c4019b3e0c3312"

# catch problematic migrations
gem "zero_downtime_migrations"

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :production, :staging do
  gem "rails_stdout_logging"
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  # gem 'byebug'

  gem "brakeman", "3.1.5"
  gem "bundler-audit"

  gem "pry"
  gem "pry-byebug"

  gem "dotenv-rails"
  gem "rubocop", "~> 0.52.1", require: false
  gem "scss_lint", require: false
end

group :test do
  gem "rspec"
  gem "rspec-rails"
  gem "timecop"
  # gem 'guard-rspec'
  gem "capybara", "2.6.2"
  gem "simplecov"
  gem "sniffybara", git: "https://github.com/department-of-veterans-affairs/sniffybara.git", branch: "axe"
  # to save and open specific page in capybara tests
  gem "database_cleaner"
  gem "launchy"
  gem "test_after_commit"
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  # gem 'web-console', '~> 2.0'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: :ruby
  gem "rb-readline"

  # For windows
  gem "tzinfo-data"
end
