require "rails_helper"

RSpec.feature "React Downloads" do
  include ActiveJob::TestHelper

  let(:documents) do
    [
      OpenStruct.new(
        document_id: SecureRandom.base64,
        series_id: "1234",
        type_id: Caseflow::DocumentTypes::TYPES.keys.sample,
        version: "1",
        mime_type: "txt",
        received_at: Time.now.utc
      ),
      OpenStruct.new(
        document_id: SecureRandom.base64,
        series_id: "5678",
        type_id: Caseflow::DocumentTypes::TYPES.keys.sample,
        version: "1",
        mime_type: "txt",
        received_at: Time.now.utc
      )
    ]
  end

  before do
    @user = User.create(css_id: "123123", station_id: "116")

    FeatureToggle.enable!(:efolder_react_app)

    User.authenticate!

    allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info).with(veteran_id).and_return(veteran_info)
    allow_any_instance_of(Fakes::BGSService).to receive(:valid_file_number?).with(veteran_id).and_return(true)

    allow(Fakes::VBMSService).to receive(:v2_fetch_documents_for).and_return(documents)
    allow(Fakes::VVAService).to receive(:v2_fetch_documents_for).and_return([])
    allow(Fakes::DocumentService).to receive(:v2_fetch_document_file).and_return("Test content")

    S3Service.files = {}

    allow(S3Service).to receive(:stream_content).and_return("streamed content")

    DownloadHelpers.clear_downloads
  end

  after do
    FeatureToggle.disable!(:efolder_react_app)
  end

  let(:veteran_id) { "12341234" }
  let(:veteran_info) do
    {
      "veteran_first_name" => "Stan",
      "veteran_last_name" => "Lee",
      "veteran_last_four_ssn" => "2222"
    }
  end

  scenario "Creating a download" do
    expect(V2::DownloadManifestJob).to receive(:perform_later).twice

    visit "/"
    expect(page).to_not have_content "Recent Searches"

    fill_in "Search for a Veteran ID number below to get started.", with: veteran_id

    click_on "Search"

    expect(page).to have_content "STAN LEE VETERAN ID #{veteran_id}"
    expect(page).to have_content "We are gathering the list of files in the eFolder now"

    manifest = Manifest.last

    expect(page).to have_css(".ee-page-loading .ee-page-loading-icon")

    expect(page).to have_current_path("/downloads/#{manifest.id}")

    expect(manifest).to_not be_nil
    expect(manifest.veteran_first_name).to eq("Stan")
    expect(manifest.veteran_last_name).to eq("Lee")
    expect(manifest.veteran_last_four_ssn).to eq("2222")
  end

  scenario "Happy path, zip file is downloaded" do
    perform_enqueued_jobs do
      visit "/"
      fill_in "Search for a Veteran ID number below to get started.", with: veteran_id

      click_button "Search"

      expect(page).to have_content "STAN LEE VETERAN ID #{veteran_id}"
      expect(page).to have_content "Start retrieving efolder"

      within(".cf-app-segment--alt") do
        click_button "Start retrieving efolder"
      end

      expect(page).to have_content("Success!")

      expect(page).to have_css ".document-success", text: Caseflow::DocumentTypes::TYPES[documents[0].type_id]

      within(".cf-app-segment--alt") do
        click_button "Download efolder"
      end

      DownloadHelpers.wait_for_download
      download = DownloadHelpers.downloaded?
      expect(download).to be_truthy

      expect(DownloadHelpers.download).to include("Lee, Stan - 2222")

      click_on "Start over"

      history_row = "#download-1"
      expect(find(history_row)).to have_content(veteran_id)
      within(history_row) { click_on("View results") }
      expect(page).to have_content("Success!")

      # Searching for this case again should take a user right to the success screen.
      click_on "Start over"
      fill_in "Search for a Veteran ID number below to get started.", with: veteran_id

      click_button "Search"
      expect(page).to have_content("Success!")

      # Even a different user searching for this case should be able to find it.
      User.authenticate!(css_id: "different_user", user_name: "different user")

      visit "/"
      fill_in "Search for a Veteran ID number below to get started.", with: veteran_id

      click_button "Search"
      expect(page).to have_content("Success!")
    end
  end

  scenario "Loading bar appears when waiting for case to download" do
    perform_enqueued_jobs do
      visit "/"
      fill_in "Search for a Veteran ID number below to get started.", with: veteran_id

      click_button "Search"

      expect(page).to have_content "STAN LEE VETERAN ID #{veteran_id}"
      expect(page).to have_content "Start retrieving efolder"
    end

    within(".cf-app-segment--alt") do
      click_button "Start retrieving efolder"
    end

    expect(page).to have_content("Retrieving Files ...")
    expect(page).to have_css ".progress-bar"
  end

  context "When manifest endpoint returns different statuses for different documents" do
    let!(:manifest) { Manifest.create(file_number: veteran_id, fetched_files_status: "pending") }
    let!(:source) do
      [
        manifest.sources.create(status: :success, name: "VBMS"),
        manifest.sources.create(status: :success, name: "VVA")
      ]
    end
    let!(:records) do
      [
        source[0].records.create(
          status: "initialized",
          version_id: "1",
          series_id: "101",
          mime_type: "application/pdf",
          type_id: Caseflow::DocumentTypes::TYPES.keys.sample
        ),
        source[0].records.create(
          status: "success",
          version_id: "2",
          series_id: "102",
          mime_type: "application/pdf",
          type_id: Caseflow::DocumentTypes::TYPES.keys.sample
        ),
        source[0].records.create(
          status: "failed",
          version_id: "3",
          series_id: "103",
          mime_type: "application/pdf",
          type_id: Caseflow::DocumentTypes::TYPES.keys.sample
        )
      ]
    end
    let!(:files_download) do
      manifest.files_downloads.find_or_create_by(
        user: User.first,
        requested_zip_at: Time.zone.now
      )
    end

    scenario "Download progress shows correct information" do
      visit "/downloads/1"

      expect(page).to have_css ".progress-bar"

      expect(page).to have_css ".cf-tab.cf-active", text: "Progress (1)"
      expect(page).to have_content "1 of 3 files remaining"
      expect(page).to have_content Caseflow::DocumentTypes::TYPES[records[0].type_id]

      click_on "Completed (1)"
      expect(page).to have_css ".cf-tab.cf-active", text: "Completed (1)"
      expect(page).to have_content Caseflow::DocumentTypes::TYPES[records[1].type_id]

      click_on "Errors (1)"
      expect(page).to have_css ".cf-tab.cf-active", text: "Errors (1)"
      expect(page).to have_content Caseflow::DocumentTypes::TYPES[records[2].type_id]

      click_on "Start over"

      history_row = "#download-1"

      expect(find(history_row)).to have_content(veteran_id)
      expect(find(history_row)).to have_css(".cf-icon-alert")
      within(history_row) { click_on("View progress") }
      expect(page).to have_content("You can close this page at any time")
    end

    context "When in progress download is older than 3 days" do
      let!(:files_download) do
        manifest.files_downloads.find_or_create_by(
          user: User.first,
          requested_zip_at: Time.zone.now - 4.days
        )
      end

      scenario "Recent download list expires old downloads" do
        visit "/"

        expect(page).to_not have_content(veteran_id)
      end
    end
  end

  context "When zipfile was created for efolder in distant past" do
    let(:veteran_id) { "808909111" }

    scenario "Viewing page for manifest with old zipfile shows search results page" do
      perform_enqueued_jobs do
        # Search for an efolder and start a download.
        visit "/"
        fill_in "Search for a Veteran ID number below to get started.", with: veteran_id
        click_button "Search"
        expect(page).to have_content "Start retrieving efolder"

        within(".cf-app-segment--alt") do
          click_button "Start retrieving efolder"
        end

        expect(page).to have_content("Success!")

        within(".cf-app-segment--alt") do
          click_button "Download efolder"
        end

        # Wait for the download to complete and return to the homepage.
        DownloadHelpers.wait_for_download
        download = DownloadHelpers.downloaded?
        expect(download).to be_truthy
        expect(DownloadHelpers.download).to include("Lee, Stan - 2222")
        click_on "Start over"

        # Change the time that we downloaded the zipfile to be some time in the distant past.
        manifest = Manifest.last
        manifest.update(fetched_files_at: Time.zone.now - 50.days)

        # Search for the same efolder and expect to see the search results page instead of the download page.
        fill_in "Search for a Veteran ID number below to get started.", with: veteran_id
        click_button "Search"

        expect(page).to have_content "Start retrieving efolder"
      end
    end
  end
end
