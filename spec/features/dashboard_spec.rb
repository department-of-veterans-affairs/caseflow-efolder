require "rails_helper"

RSpec.feature "Stats Dashboard" do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 17, 0, 0))

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
      ),

      Download.create(
        user_id: "CREED",
        user_station_id: "204",
        status: :complete_success,
        created_at: 4.hours.ago - 16.37,
        manifest_fetched_at: 4.hours.ago,
        started_at: 4.hours.ago,
        completed_at: 3.hours.ago
      ),

      Download.create(
        user_id: "DRAGO",
        user_station_id: "205",
        status: :complete_success,
        created_at: 4.hours.ago - 20.37,
        manifest_fetched_at: 4.hours.ago,
        started_at: 4.hours.ago,
        completed_at: 3.hours.ago
      ),

      Download.create(
        user_id: "THUNDERLIPS",
        user_station_id: "206",
        status: :complete_success,
        created_at: 4.hours.ago - 30.37,
        manifest_fetched_at: 4.hours.ago,
        started_at: 4.hours.ago,
        completed_at: 3.hours.ago
      )
    ]

    @downloads.last.searches.create(email: "thunderlips@example.com", user_id: "THUNDERLIPS")

    @downloads.each do |download|
      download.documents.create(
        download_status: :success,
        completed_at: 3.hours.ago
      )
      download.documents.create(
        download_status: :success,
        completed_at: 3.hours.ago
      )
      download.documents.create(
        download_status: :failed,
        completed_at: 3.hours.ago
      )
    end
  end

  after { Timecop.return }

  scenario "Vist from unauthenticated user" do
    User.authenticate!

    visit "/stats"
    expect(page).to have_content("authorized")
  end

  scenario "Switching tab intervals" do
    User.authenticate!(roles: ["System Admin"])

    visit "/stats"
    expect(page).to have_content("Activity for 12:00–12:59 EST (so far)")
    expect(page).to have_content("Active Users 0")
    expect(page).to have_content("Completed Downloads 0")
    expect(page).to have_content("Documents Retrieved 0")

    click_on "Daily"
    expect(page).to have_content("Activity for January 1 (so far)")
    expect(page).to have_content("Active Users 4")
    expect(page).to have_content("Completed Downloads 6")
    expect(page).to have_content("Documents Retrieved 12")
    expect(page).to have_content("Document Errors 6")
    expect(page).to have_content("Time to Manifest (median) 16.37 sec")
    expect(page).to have_content("Time to Files (median) 60.00 min")
    expect(page).to have_content("No Email Recorded (ROCKY - Station 203) 3 Downloads")
    expect(page).to have_content("thunderlips@example.com (THUNDERLIPS - Station 206) 1 Download")
    expect(page).to have_content("No Email Recorded (DRAGO - Station 205) 1 Download")
  end

  scenario "Toggle median to 95th percentile" do
    User.authenticate!(roles: ["System Admin"])

    visit "/stats"
    click_on "Daily"

    find('*[role="button"]', text: "Time to Manifest").trigger("click")
    expect(page).to have_content("Time to Manifest (95th percentile) 30.37 sec")
    find('*[role="button"]', text: "Time to Manifest").trigger("click")
    expect(page).to have_content("Time to Manifest (median) 16.37 sec")
  end

  scenario "Navigate to past periods with arrow keys" do
    leftarrow = "d3.select(window).dispatch('keydown', { detail: { keyCode: 37 } })"

    User.authenticate!(roles: ["System Admin"])

    visit "/stats"
    click_on "Monthly"
    expect(page).to have_content("Activity for January (so far)")

    12.times do
      page.driver.execute_script(leftarrow)
    end

    expect(page).to have_content("Activity for January 2014")
  end
end
