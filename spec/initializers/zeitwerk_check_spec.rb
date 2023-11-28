# frozen_string_literal: true
require "rails_helper"

# See config/initializers/zeitwerk.rb if this fails
RSpec.describe "Zeitwerk Compliance Check" do
  it "Eager loads all files without errors" do
    expect { Rails.application.eager_load! }.not_to raise_error
  end
end