require "rubygems"

if ENV["SINGLE_COV"]
  # get coverage selectively in local dev
  # add the line 'SingleCov.covered!' to the top of any *_spec.rb file to enable.
  require "single_cov"
  SingleCov.setup :rspec
else
  # default is aggregate via simplecov for CI
  require "simplecov"

  SimpleCov.start do
    add_filter "lib/fakes"
    add_filter "config/initializers"
    add_filter "spec/support"
    add_filter "app/services/external_api/vbms_service.rb"
    add_filter "app/services/external_api/bgs_service.rb"
    add_filter "app/services/external_api/vva_service.rb"
    add_filter "app/jobs"

    SimpleCov.minimum_coverage_by_file 90
  end
end

if ENV["CI"]
  require "rspec/retry"
  # Repeat all failed feature tests in CI twice
  RSpec.configure do |config|
    # show retry status in spec process
   config.verbose_retry = true
    # show exception that triggers a retry if verbose_retry is set to true
    config.display_try_failure_messages = true
    # run retry twice only on features
    config.around :each, type: :feature do |ex|
      ex.run_with_retry retry: 2
    end
  end
end

def test_large_files?
  ENV.fetch("TEST_LARGE_FILES", false)
end

def test_downloads?
  ENV.fetch("TEST_DOWNLOADS", false)
end

#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.filter_run_excluding download: true unless test_downloads?

  config.filter_run_excluding :large_files unless test_large_files?

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.example_status_persistence_file_path = "tmp/examples.txt"

  # Test User ID set for repeated download testing:
  ENV["TEST_USER_ID"] = "321321"
end
