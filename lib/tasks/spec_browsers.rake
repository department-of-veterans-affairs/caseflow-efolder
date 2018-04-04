begin
  require "rspec"

  namespace :spec do
    desc "Run the feature specs on supported browsers"

    Rake::Task["assets:precompile"].execute

    RSpec::Core::RakeTask.new(:browsers) do |t|
      t.pattern = "spec/feature/**/*_spec.rb"
    end
  end
  # rubocop:disable Lint/HandleExceptions
rescue LoadError, NameError
end
# rubocop:enable Lint/HandleExceptions
