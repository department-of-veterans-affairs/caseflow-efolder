require "rails_helper"

RSpec.feature "Stats Dashboard" do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))

    Download.delete_all
  end

  scenario "Switching tab intervals" do
    Download.create(
      status: :complete_with_errors,
      created_at: 6.hours.ago - 10.37,
      manifest_fetched_at: 6.hours.ago,
      started_at: 5.hours.ago,
      completed_at: 4.hours.ago
    )

    visit "/stats"
    expect(page).to have_content("Completed Downloads 0")

    click_on "Daily"
    expect(page).to have_content("Completed Downloads 1")
    expect(page).to have_content("Time to Manifest (95 %tile) 10.37 sec")
    expect(page).to have_content("Time to Files (95 %tile) 60.00 min")
  end
end
