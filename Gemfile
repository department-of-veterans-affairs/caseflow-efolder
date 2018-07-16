# frozen_string_literal: true

source ENV["GEM_SERVER_URL"] || "https://rubygems.org"

gem "caseflow", git: "https://github.com/department-of-veterans-affairs/caseflow-commons", ref: "8dde00d67b7c629e4b871f8dcb3617bfe989b3db"

gem "moment_timezone-rails"

# Use sqlite3 as the database for Active Record
gem "sqlite3", platforms: [:ruby, :mswin, :mingw, :mswin, :x64_mingw]

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "5.1.5"

gem "activerecord-jdbcpostgresql-adapter", platforms: :jruby

# pg version that is compatible with Rails 5
gem "pg", "~> 0.18", platforms: :ruby

gem "aws-sdk", "~> 2"

gem "prometheus-client", "~> 0.7.1"

gem "activejob_dj_overrides"

# Use SCSS for stylesheets
gem "sass-rails", "~> 5.0"
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"
# Use CoffeeScript for .coffee assets and views
gem "coffee-rails", "> 4.1.0"

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
gem "omniauth-saml-va", git: "https://github.com/department-of-veterans-affairs/omniauth-saml-va", ref: "fbe2b878c250b14ee996ef6699c42df2c42e41a1"

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

gem "rubyzip"

# use to_b method to convert string to boolean
gem "wannabe_bool"

gem "zaru"

gem "listen"

gem "active_model_serializers"

gem "redis-namespace"
gem "redis-semaphore"

gem "request_store"

gem "mini_magick"

gem "httpclient"

gem "bgs", git: "https://github.com/department-of-veterans-affairs/ruby-bgs.git", branch: "b8b6d0f918d855b61b31f03e01a39d802d587367"
gem "connect_vbms", git: "https://github.com/department-of-veterans-affairs/connect_vbms.git", ref: "d91deab540d7bc46822db1226a382d3deacc7535"
gem "connect_vva", git: "https://github.com/department-of-veterans-affairs/connect_vva.git", ref: "ecc1da3f1027e6c270af264de46dc1cb4974fa47"

# catch problematic migrations
gem "zero_downtime_migrations"

gem "mime-types"

gem "shoryuken", "3.1.11"

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
  gem "capybara", "2.6.2"
  gem "rspec"
  gem "rspec-rails"
  gem "simplecov"
  gem "sniffybara", git: "https://github.com/department-of-veterans-affairs/sniffybara.git"
  gem "timecop"
  # to save and open specific page in capybara tests
  gem "database_cleaner"
  gem "launchy"
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
