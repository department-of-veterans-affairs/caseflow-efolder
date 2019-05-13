require "rails_helper"

RSpec.feature "Send feedback" do
  before do
    User.authenticate!
  end

  scenario "Sending feedback about eFolder Express" do
    visit "/"

    expect(page).to have_link("Send feedback")

    href = find_link("Send feedback")["href"]
    expect(href).to match(/\/feedback$/)
  end
end
