# frozen_string_literal: true

source ENV["GEM_SERVER_URL"] || "https://rubygems.org"

gem "active_model_serializers"
gem "activejob_dj_overrides"
gem "aws-sdk", "~> 2"
gem "bgs", git: "https://github.com/department-of-veterans-affairs/ruby-bgs.git", ref: "98547485d863f2f0d3bb9a1b9ec92a8fe21ba306"
gem "bootsnap", require: false
gem "caseflow", git: "https://github.com/department-of-veterans-affairs/caseflow-commons", ref: "098177b58e35384d7b5c923ebe4920f69165d1c5"
gem "coffee-rails", "> 4.1.0"
gem "connect_vbms", git: "https://github.com/department-of-veterans-affairs/connect_vbms.git", branch: "9807d9c9f0f3e3494a60b6693dc4f455c1e3e922"
gem "connect_vva", git: "https://github.com/department-of-veterans-affairs/connect_vva.git", ref: "dfd1aeb2605c1f237f520bcdc41b059202e8944d"
gem "distribute_reads"
gem "dogstatsd-ruby"
gem "httpclient"
gem "jbuilder", "~> 2.0"
gem "jquery-rails", ">= 4.3.4"
gem "listen"
gem "logstasher"
gem "mime-types"
gem "mini_magick"
gem "moment_timezone-rails"
gem "newrelic_rpm"
gem "nokogiri", ">=1.10.5"
gem "omniauth-saml-va", git: "https://github.com/department-of-veterans-affairs/omniauth-saml-va", branch: "pek-iam-ssoi"
#gem "omniauth-saml-va", git: "https://github.com/department-of-veterans-affairs/omniauth-saml-va", ref: "fbe2b878c250b14ee996ef6699c42df2c42e41a1"
gem "pg", "~> 0.18", platforms: :ruby
gem "puma", "6.4.2"
gem "rack-cors", ">= 1.0.4"
gem "rails", "5.2.8.1"
gem "redis-namespace"
gem "redis-rails", "~> 5.0.2"
gem "redis-semaphore"
gem "request_store"
gem "rubyzip", ">= 1.3.0"
gem "sass-rails", "~> 5.0"
gem "sentry-raven"
gem "shoryuken", "3.1.11"
gem "therubyracer", platforms: :ruby
gem "turbolinks"
gem "uglifier", ">= 1.3.0"
gem "uswds-rails", git: "https://github.com/18F/uswds-rails-gem.git"
gem "wannabe_bool"
gem "zaru"
gem "zero_downtime_migrations"

group :development, :production, :staging do
  gem "rails_stdout_logging"
end

group :development, :test do
  gem "brakeman"
  gem "bundler-audit"
  gem "dotenv-rails"
  gem "pry"
  gem "pry-byebug"
  gem "rubocop", "~> 0.67.2", require: false
  gem "scss_lint", require: false
end

group :test do
  gem "capybara"
  gem "capybara-screenshot"
  gem "database_cleaner"
  gem "launchy"
  gem "rspec"
  gem "rspec-github", require: false # Github Actions Annotations Formatter
  gem "rspec-rails"
  gem "rspec-retry"
  gem "saml_idp", git: "https://github.com/18F/saml_idp.git", branch: "master"
  gem "simplecov", require: false
  gem "sinatra", "2.2.0"
  gem "single_cov", require: false
  gem "sniffybara", git: "https://github.com/department-of-veterans-affairs/sniffybara.git"
  gem "timecop"
  gem "webdrivers"
  gem "webmock"
end

group :development do
  gem "byebug", platforms: :ruby
  gem "rb-readline"

  # For windows
  gem "tzinfo-data"
end
