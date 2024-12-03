# frozen_string_literal: true

source ENV["GEM_SERVER_URL"] || "https://rubygems.org"

gem "active_model_serializers"
gem "activejob_dj_overrides"
gem "aws-sdk-core", "3.131.0"
gem "aws-sdk-ec2"
gem "aws-sdk-s3"
gem "aws-sdk-sqs"
gem "bgs", git: "https://github.com/department-of-veterans-affairs/ruby-bgs-internal.git", ref: "a2e055b5a52bd1e2bb8c2b3b8d5820b1a404cd3d"
gem "bootsnap", require: false
gem "caseflow", git: "https://github.com/department-of-veterans-affairs/caseflow-commons-internal.git", ref: "f85d4ce99c371359b18699310ef66a2f9ca35121"
gem "coffee-rails", "> 4.1.0"
gem "connect_vbms", git: "https://github.com/department-of-veterans-affairs/connect_vbms-internal.git", ref: "1834cf61310001c82e2e96d665518407c3bce947"
gem "connect_vva", git: "https://github.com/department-of-veterans-affairs/connect_vva-internal.git", ref: "f7913cd30ab5a75fb8bbc55dfc76743f362dba58"
gem "distribute_reads"
gem "httpclient"
gem "jbuilder", "~> 2.0"
gem "jquery-rails", ">= 4.3.4"
gem "listen"
gem "logstasher"
gem "mime-types"
gem "mini_magick"
gem "moment_timezone-rails"
gem "nokogiri", ">=1.10.5"
gem "statsd-instrument"

# OpenTelemetry instruments
gem "opentelemetry-exporter-otlp", require: false
gem "opentelemetry-sdk", require: false

gem "opentelemetry-instrumentation-action_pack", require: false
gem "opentelemetry-instrumentation-action_view", require: false
gem "opentelemetry-instrumentation-active_job", require: false
gem "opentelemetry-instrumentation-active_model_serializers", require: false
gem "opentelemetry-instrumentation-active_record", require: false
gem "opentelemetry-instrumentation-aws_sdk", require: false
gem "opentelemetry-instrumentation-concurrent_ruby", require: false
gem "opentelemetry-instrumentation-faraday", require: false
gem "opentelemetry-instrumentation-http", require: false
gem "opentelemetry-instrumentation-http_client", require: false
gem "opentelemetry-instrumentation-net_http", require: false
gem "opentelemetry-instrumentation-pg", require: false
gem "opentelemetry-instrumentation-rack", require: false
gem "opentelemetry-instrumentation-rails", require: false
gem "opentelemetry-instrumentation-rake", require: false
gem "opentelemetry-instrumentation-redis", require: false

# gem "omniauth-saml-va", git: "https://github.com/department-of-veterans-affairs/omniauth-saml-va", branch: "pek-iam-ssoi"
gem "omniauth-saml-va", git: "https://github.com/department-of-veterans-affairs/omniauth-saml-va-internal", ref: "7409f77b9ec5348a27a059e48b7df93471f0acdd"
gem "pg", "~> 1.5.7", platforms: :ruby
gem "puma", "5.6.9"
gem "rack-cors", ">= 1.0.4"
gem "rails", "6.1.7.4"
gem "redis-namespace"
gem "redis-rails", "~> 5.0.2"
gem "redis-semaphore"
gem "request_store"
gem "ruby_claim_evidence_api", git: "https://github.com/department-of-veterans-affairs/clone_ruby_claim_evidence_api.git", ref: "c56381d2bea2ffabe79bebbac6598f00450691ff"
gem "rubyzip", ">= 1.3.0"
gem "sass-rails", "~> 5.0"
gem "sentry-raven"
gem "shoryuken", "3.1.11"
gem "turbolinks"
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
  gem "rubocop", "= 0.83", require: false
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
  gem "sniffybara", git: "https://github.com/department-of-veterans-affairs/sniffybara-internal.git"
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
