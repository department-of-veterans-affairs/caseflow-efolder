# frozen_string_literal: true

require "capybara/rspec"
require "capybara-screenshot/rspec"
require "selenium-webdriver"
require "webdrivers"

# make sure we have latest (CircleCI may have cached older version)
Webdrivers::Chromedriver.update

Webdrivers.logger.level = :debug if ENV["DEBUG"]

Sniffybara::Driver.run_configuration_file = File.expand_path("VA-axe-run-configuration.json", __dir__)

tmp_directory = Rails.root.join("tmp").to_s
download_directory = Rails.root.join("tmp/downloads_all").to_s
cache_directory = Rails.root.join("tmp/browser_cache_all").to_s

Dir.mkdir tmp_directory unless File.directory?(tmp_directory)
Dir.mkdir download_directory unless File.directory?(download_directory)
if File.directory?(cache_directory)
  FileUtils.rm_r cache_directory
else
  Dir.mkdir cache_directory
end

Capybara.register_driver(:parallel_sniffybara) do |app|
  chrome_options = ::Selenium::WebDriver::Chrome::Options.new

  chrome_options.add_preference(:download,
                                prompt_for_download: false,
                                default_directory: download_directory)

  chrome_options.add_preference(:browser,
                                disk_cache_dir: cache_directory)

  service = ::Selenium::WebDriver::Service.chrome
  service.port = 51_674

  options = {
    service: service,
    browser: :chrome,
    options: chrome_options
  }
  Sniffybara::Driver.register_specialization(
    :chrome, Capybara::Selenium::Driver::ChromeDriver
  )
  Sniffybara::Driver.current_driver = Sniffybara::Driver.new(app, options)
end

Capybara.register_driver(:sniffybara_headless) do |app|
  chrome_options = ::Selenium::WebDriver::Chrome::Options.new

  chrome_options.add_preference(:download,
                                prompt_for_download: false,
                                default_directory: download_directory)

  chrome_options.add_preference(:browser,
                                set_download_behavior: { behavior: 'allow' },
                                download_path: download_directory,
                                disk_cache_dir: cache_directory)

  chrome_options.add_preference(:safebrowsing,
                                enabled: false,
                                disable_download_protection: true)

  chrome_options.args << "--headless"
  chrome_options.args << "--disable-gpu"
  chrome_options.args << "--window-size=1200,1200"
  chrome_options.args << "--enable-logging=stderr --v=1"
  # arguments below were needed to fix Github Actions Chromedriver issue 
  chrome_options.args << "--disable-dev-shm-usage"
  chrome_options.args << "--disable-impl-side-painting"

  service = ::Selenium::WebDriver::Service.chrome
  service.port = 51_674

  options = {
    service: service,
    browser: :chrome,
    options: chrome_options
  }

  Sniffybara::Driver.register_specialization(
    :chrome, Capybara::Selenium::Driver::ChromeDriver
  )
  Sniffybara::Driver.current_driver = Sniffybara::Driver.new(app, options)
end

Capybara::Screenshot.register_driver(:parallel_sniffybara) do |driver, path|
  driver.browser.save_screenshot(path)
end

Capybara::Screenshot.register_driver(:sniffybara_headless) do |driver, path|
  driver.browser.save_screenshot(path)
end

Capybara.default_driver = ENV["CI"] ? :sniffybara_headless : :parallel_sniffybara
# the default default_max_wait_time is 2 seconds
Capybara.default_max_wait_time = 5
# Capybara uses puma by default, but for some reason, some of our tests don't
# pass with puma. See: https://github.com/teamcapybara/capybara/issues/2170
Capybara.server = :webrick

# backcompat with version 2.x where "foo bar" would also match "foo\nbar"
Capybara.default_normalize_ws = true
