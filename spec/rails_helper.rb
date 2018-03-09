# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../config/environment", __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "spec_helper"
require "rspec/rails"
require_relative "support/database_cleaner"
require_relative "support/download_helper"
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

require "selenium-webdriver"
require "capybara"

Sniffybara::Driver.path_exclusions << /samlva/
Sniffybara::Driver.configuration_file = File.expand_path("../support/VA-axe-configuration.json", __FILE__)
Sniffybara::Driver.issue_id_exceptions += []

download_directory = Rails.root.join("tmp", "downloads_all")
cache_directory = Rails.root.join("tmp", "browser_cache_all")

FileUtils.mkpath download_directory unless File.directory?(download_directory)
if File.directory?(cache_directory)
  FileUtils.rm_r cache_directory
else
  Dir.mkdir cache_directory
end

Capybara.register_driver(:virtual_framebuffer_chrome) do |app|
  chrome_options = ::Selenium::WebDriver::Chrome::Options.new

  chrome_options.add_preference(:download,
                                prompt_for_download: false,
                                default_directory: download_directory)

  chrome_options.add_preference(:browser,
                                disk_cache_dir: cache_directory)

  options = {
    port: 51_674,
    browser: :chrome,
    options: chrome_options
  }

  Sniffybara::Driver.current_driver = Sniffybara::Driver.new(app, options)
end
Capybara.default_driver = :virtual_framebuffer_chrome

# Convenience methods for stubbing current user
module StubbableUser
  module ClassMethods
    def stub=(user)
      @stub = user
    end

    def authenticate!(options = {})
      Functions.grant!("System Admin", users: ["123123"]) if options[:roles]&.include?("System Admin")

      self.stub = find_or_create_by(css_id: "123123", station_id: "116").tap do |u|
        u.name = "first last"
        u.email = "test@gmail.com"
        u.roles = options[:roles] || ["Download eFolder"]
        u.save
        RequestStore.store[:current_user] = u
      end
    end

    def tester!(options = {})
      self.stub = find_or_create_by(css_id: ENV["TEST_USER_ID"], station_id: "116").tap do |u|
        u.name = "first last"
        u.email = "test@gmail.com"
        u.roles = options[:roles] || ["Download eFolder"]
        u.save
      end
    end

    def unauthenticate!
      Functions.delete_all_keys!
      RequestStore.store[:current_user] = nil
      self.stub = nil
    end

    def from_session_and_request(session, request)
      @stub || super(session, request)
    end
  end

  def self.prepended(base)
    class << base
      prepend ClassMethods
    end
  end
end
User.prepend(StubbableUser)

module RandomHelper
  def self.valid_document_id
    "{#{SecureRandom.uuid.upcase}}"
  end
end

RSpec.configure do |config|
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.before(:all) do
    User.unauthenticate!
  end

  config.after(:each) do
    Rails.cache.clear
  end

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end
