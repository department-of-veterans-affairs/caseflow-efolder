# frozen_string_literal: true

source ENV["GEM_SERVER_URL"] || "https://rubygems.org"

gem "active_model_serializers"
gem "activejob_dj_overrides"
gem "activerecord-jdbcpostgresql-adapter", platforms: :jruby
gem "aws-sdk", "~> 2"
gem "bgs", git: "https://github.com/department-of-veterans-affairs/ruby-bgs.git", ref: "8257194357a282bc8846630b9a00e8905117ac59"
gem "caseflow", git: "https://github.com/department-of-veterans-affairs/caseflow-commons", ref: "ffb77dd0395cbd5b7c1a5729f7f8275b5ec681fa"
gem "coffee-rails", "> 4.1.0"
gem "connect_vbms", git: "https://github.com/department-of-veterans-affairs/connect_vbms.git", ref: "dc5776ae4d9674b035789b74072e8032a9cf6e45"
gem "connect_vva", git: "https://github.com/department-of-veterans-affairs/connect_vva.git", ref: "dfd1aeb2605c1f237f520bcdc41b059202e8944d"
gem "distribute_reads"
gem "dogstatsd-ruby"
gem "httpclient"
gem "jbuilder", "~> 2.0"
gem "jquery-rails", ">= 4.3.4"
gem "listen"
gem "mime-types"
gem "mini_magick"
gem "moment_timezone-rails"
gem "newrelic_rpm"
gem "nokogiri", ">=1.10.5"
gem "omniauth-saml-va", git: "https://github.com/department-of-veterans-affairs/omniauth-saml-va", ref: "fbe2b878c250b14ee996ef6699c42df2c42e41a1"
gem "pg", "~> 0.18", platforms: :ruby
gem "puma"
gem "rack-cors", ">= 1.0.4"
gem "rails", "5.1.6.2"
gem "redis-namespace"
gem "redis-rails", "~> 5.0.2"
gem "redis-semaphore"
gem "request_store"
gem "rubyzip", ">= 1.3.0"
gem "sass-rails", "~> 5.0"
gem "sdoc", "~> 0.4.0", group: :doc
gem "sentry-raven"
gem "shoryuken", "3.1.11"
gem "therubyracer", platforms: :ruby
gem "therubyrhino", platforms: :jruby
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
  gem "brakeman", "3.1.5"
  gem "bundler-audit"
  gem "dotenv-rails"
  gem "pry"
  gem "pry-byebug"
  gem "rubocop", "~> 0.52.1", require: false
  gem "scss_lint", require: false
end

group :test do
  gem "capybara", "2.6.2"
  gem "database_cleaner"
  gem "launchy"
  gem "rspec"
  gem "rspec-rails"
  gem "simplecov"
  gem "sniffybara", git: "https://github.com/department-of-veterans-affairs/sniffybara.git"
  gem "timecop"
  gem "webmock"
end

group :development do
  gem "byebug", platforms: :ruby
  gem "rb-readline"

  # For windows
  gem "tzinfo-data"
end
