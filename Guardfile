# frozen_string_literal: true

guard :rspec, cmd: "bundle exec rspec" do
  watch(%r{spec/.*/}) { "spec" }
  watch(%r{app/.*/}) { "spec" }
end
