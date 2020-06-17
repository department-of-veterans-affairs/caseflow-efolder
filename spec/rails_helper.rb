# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../config/environment", __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "spec_helper"
require "rspec/rails"

# Add additional requires below this line. Rails is not loaded until this point!

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# The TZ variable controls the timezone of the browser in capybara tests, so we always define it.
# By default (esp for CI) we use Eastern time, so that it doesn't matter where the developer happens to sit.
#ENV["TZ"] ||= "America/New_York"

# Assume the browser and the server are in the same timezone for now. Eventually we should
# use something like https://github.com/alindeman/zonebie to exercise browsers in different timezones.
#Time.zone = ENV["TZ"]

module RandomHelper
  def self.valid_document_id
    "{#{SecureRandom.uuid.upcase}}"
  end
end

# Wrap this around your test to run it many times and ensure that it passes consistently.
# Note: do not merge to master like this, or the tests will be slow! Ha.
def ensure_stable
  repeat_count = ENV.fetch("ENSURE_STABLE", "10").to_i
  repeat_count.times do
    yield
  end
end

RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.before(:all) do
    User.unauthenticate!
  end

  config.after(:each) do
    Rails.cache.clear
  end

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!

  config.before(:each) do
    stub_request(:any, /idp.example.com/).to_rack(FakeSamlIdp)
  end
end
