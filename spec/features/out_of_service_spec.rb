require "rails_helper"

RSpec.feature "Out of Service" do
  context "Out of service is disabled" do
    scenario "Visit root page" do
      visit "/"
      expect(page).not_to have_content("Technical Difficulties")
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
