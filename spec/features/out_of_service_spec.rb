require "rails_helper"

RSpec.feature "Out of Service" do
  before do
    FeatureToggle.enable!(:use_ssoi_iam) # must align with config/initializers/omniauth
  end

  after do
    FeatureToggle.disable!(:use_ssoi_iam)
  end

  context "Out of service is disabled" do
    context "user is already authenticated" do
      before { User.authenticate! }

      scenario "Visit root page" do
        visit "/"
        expect(page).not_to have_content("Technical Difficulties")
      end
    end

    context "user is not authenticated" do
      before { User.unauthenticate! }

      scenario "Visit root page" do
        visit "/"
        expect(page).not_to have_content("Technical Difficulties")
      end
    end
  end

  context "Out of service is enabled" do
    before do
      Rails.cache.write("out_of_service", true)
    end

    scenario "Visit root page" do
      visit "/"
      expect(page).to have_content("Technical Difficulties")
    end
  end
end
