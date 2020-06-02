require "rails_helper"

RSpec.feature "Authentication" do
  scenario "Unauthenticated request bounces to login page" do
    visit("/")
    expect(current_path).to eq("/login")
  end

  # We cannot test /logout flow as a feature test
  # under IAM SAML because our fake IdP uses idp.example.com
  # which our browser does not know how to resolve.
  # Instead we test authentication flows as spec/requests/*

  context "when user has access to efolder react app" do
    before do
      User.authenticate!
    end

    let(:user) { User.create(css_id: "123123", station_id: "116") }

    scenario "coachmarks are not displayed indicating that we are viewing the react app" do
      visit "/"
      expect(page).to_not have_content("See what's new!")
    end
  end
end
