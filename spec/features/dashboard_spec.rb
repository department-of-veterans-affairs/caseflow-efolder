require "rails_helper"

RSpec.feature "Stats Dashboard" do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))

    Download.delete_all
    Document.delete_all

    @downloads = [
      Download.create(
        user_id: "ROCKY",
        user_station_id: "203",
        status: :complete_with_errors,
        created_at: 6.hours.ago - 10.37,
        manifest_fetched_at: 6.hours.ago,
        started_at: 4.hours.ago,
        completed_at: 3.hours.ago
      ),

      Download.create(
        user_id: "ROCKY",
        user_station_id: "203",
        status: :complete_success,
        created_at: 5.hours.ago - 12.37,
        manifest_fetched_at: 5.hours.ago,
        started_at: 4.hours.ago,
        completed_at: 3.hours.ago
      ),

      Download.create(
        user_id: "ROCKY",
        user_station_id: "203",
        status: :complete_success,
        created_at: 4.hours.ago - 14.37,
        manifest_fetched_at: 4.hours.ago,
        started_at: 4.hours.ago,
        completed_at: 3.hours.ago
      )
    ]

    @downloads.each do |download|
      download.documents.create(download_status: :success)
      download.documents.create(download_status: :success)
      download.documents.create(download_status: :failed)
    end
  end

  after { Timecop.return }

  scenario "Vist from unauthenticated user" do
    User.authenticate!

    visit "/stats"
    expect(page).to have_content("Unauthorized")
  end

  scenario "Switching tab intervals" do
    User.authenticate!(roles: ["System Admin"])

    visit "/stats"
    expect(page).to have_content("Active Users 0")
    expect(page).to have_content("Completed Downloads 0")
    expect(page).to have_content("Documents Retrieved 0")

    click_on "Daily"
    expect(page).to have_content("Active Users 1")
    expect(page).to have_content("Completed Downloads 3")
    expect(page).to have_content("Documents Retrieved 6")
    expect(page).to have_content("Time to Manifest (median) 12.37 sec")
    expect(page).to have_content("Time to Files (median) 60.00 min")

    expect(page).to have_content("Most Active Users ROCKY (Station 203) 3 Downloads")
  end

  scenario "Toggle median to 95th percentile" do
    User.authenticate!(roles: ["System Admin"])

    visit "/stats"
    click_on "Daily"

    find('*[role="button"]', text: "Time to Manifest").click
    expect(page).to have_content("Time to Manifest (95th percentile) 14.37 sec")
    find('*[role="button"]', text: "Time to Manifest").click
    expect(page).to have_content("Time to Manifest (median) 12.37 sec")
  end
end
