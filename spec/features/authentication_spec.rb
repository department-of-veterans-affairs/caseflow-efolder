require "rails_helper"

RSpec.feature "Authentication" do
  before do
    @user = User.create(css_id: "123123", station_id: "116")

    FeatureToggle.enable!(:efolder_react_app)

    User.authenticate!
  end

  after do
    FeatureToggle.disable!(:efolder_react_app)
  end

  scenario "Not login bounces to login page" do
    User.unauthenticate!

    visit("/")
    expect(page).to have_content("Test VA Saml")
    fill_in "css_id", with: "css_id"
    fill_in "station_id", with: "station_id"
    click_on "Sign In"

    puts page.current_path
    expect(page).to have_current_path("/")
  end

  scenario "Logging out" do
    User.unauthenticate!

    visit("/")
    fill_in "css_id", with: "css_id"
    fill_in "station_id", with: "station_id"
    click_on "Sign In"

    click_on "First Last"
    click_on "Sign out"
    expect(page).to have_content("Test VA Saml")
  end

  context "when user has access to efolder react app" do
    before { FeatureToggle.enable!(:efolder_react_app, users: [@user.css_id]) }
    after { FeatureToggle.disable!(:efolder_react_app, users: [@user.css_id]) }

    scenario "coachmarks are not displayed indicating that we are viewing the react app" do
      visit "/"
      expect(page).to_not have_content("See what's new!")
    end
  end
end
