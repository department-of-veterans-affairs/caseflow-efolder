# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Send feedback" do
  before do
    User.authenticate!
  end

  scenario "Sending feedback about eFolder Express" do
    visit "/"

    expect(page).to have_link("Send feedback")

    href = find_link("Send feedback")["href"]
    expect(href.include?(ENV["CASEFLOW_FEEDBACK_URL"])).to be true
    expect(href.include?("subject=eFolder+Express")).to be true
    expect(href.include?("redirect=")).to be true
  end
end
