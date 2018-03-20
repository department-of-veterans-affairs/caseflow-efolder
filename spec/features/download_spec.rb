require "rails_helper"
# require "sidekiq/testing"

RSpec.feature "Downloads" do
  include ActiveJob::TestHelper

  let(:documents) do
    [
      OpenStruct.new(
        document_id: "1",
        series_id: "1234",
        type_id: Caseflow::DocumentTypes::TYPES.keys.sample,
        version: "1",
        mime_type: "txt",
        received_at: Time.now.utc
      ),
      OpenStruct.new(
        document_id: "2",
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
    allow_any_instance_of(Fakes::BGSService).to receive(:valid_file_number?).with(invalid_veteran_id).and_return(false)

    allow(Fakes::DocumentService).to receive(:v2_fetch_documents_for).and_return(documents)
    allow(Fakes::DocumentService).to receive(:v2_fetch_document_file).and_return("Test content")

    S3Service.files = {}

    allow(S3Service).to receive(:stream_content).and_return("streamed content")

    DownloadHelpers.clear_downloads
  end

  after do
    FeatureToggle.disable!(:efolder_react_app)
  end

  let(:root_path) { "/" }

  let(:invalid_veteran_id) { "abcd" }

  let(:veteran_id) { "12341234" }
  let(:veteran_info) do
    {
      "veteran_first_name" => "Stan",
      "veteran_last_name" => "Lee",
      "veteran_last_four_ssn" => "2222"
    }
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

  context "When there is a download with no documents" do
    let(:manifest) do
      Manifest.create!(
        file_number: veteran_id
      )
    end

    let!(:sources) do
      [
        manifest.sources.create(name: "VVA", status: :success, fetched_at: 2.hours.ago),
        manifest.sources.create(name: "VBMS", status: :success, fetched_at: 2.hours.ago)
      ]
    end

    scenario "Searching for it shows the no documents page" do
      visit "/"
      fill_in "Search for a Veteran ID number below to get started.", with: veteran_id
      click_button "Search"

      expect(page).to have_css ".cf-msg-screen-heading", text: "No Documents in eFolder"
      expect(page).to have_content manifest.file_number

      click_on "search again"
      expect(page).to have_current_path(root_path)
    end
  end

  context "When downloading documents is successful" do
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

        click_on "Start over"
        fill_in "Search for a Veteran ID number below to get started.", with: veteran_id

        click_button "Search"
        expect(page).to have_content("Success!")
      end
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

  scenario "Extraneous spaces in search input" do
    visit "/"

    fill_in "Search for a Veteran ID number below to get started.", with: " #{veteran_id} "
    click_button "Search"

    expect(page).to have_content "STAN LEE VETERAN ID #{veteran_id}"

    expect(Manifest.where(file_number: veteran_id).count).to eq(1)
  end

  scenario "Requesting invalid case number" do
    visit "/"

    fill_in "Search for a Veteran ID number below to get started.", with: invalid_veteran_id
    click_button "Search"

    expect(page).to have_content("File number is invalid")
  end

  context "When veteran_id has no veteran info" do
    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info).with(veteran_id).and_return(nil)
    end

    scenario "Requesting veteran_id returns cannot find eFolder" do
      visit "/"
      fill_in "Search for a Veteran ID number below to get started.", with: veteran_id

      click_button "Search"
      expect(page).to have_content("could not find an eFolder with the Veteran ID")
    end
  end

  context "When veteran id has high sensitivity" do
    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:sensitive_files).and_return(veteran_id => true)
    end

    scenario "Cannot access it" do
      visit "/"
      fill_in "Search for a Veteran ID number below to get started.", with: veteran_id
      click_button "Search"

      expect(page).to have_content("forbidden: sensitive record")
    end
  end

  context "When veteran case folder has no documents" do
    before do
      allow(Fakes::DocumentService).to receive(:v2_fetch_documents_for).and_return([])
    end

    scenario "Download with no documents" do
      perform_enqueued_jobs do
        visit "/"
        fill_in "Search for a Veteran ID number below to get started.", with: veteran_id
        click_button "Search"

        expect(page).to have_css ".cf-msg-screen-heading", text: "No Documents in eFolder"
        expect(page).to have_content veteran_id

        click_on "search again"
        expect(page).to have_current_path(root_path)
      end
    end
  end

  context "When VBMS returns an error" do
    before do
      allow(Fakes::VBMSService).to receive(:v2_fetch_documents_for).and_raise(VBMS::ClientError)
    end

    scenario "Download with VBMS connection error" do
      perform_enqueued_jobs do
        visit "/"
        fill_in "Search for a Veteran ID number below to get started.", with: veteran_id
        click_button "Search"

        expect(page).to have_css ".usa-alert-heading", text: "We are having trouble connecting to VBMS"
        click_link "Back to eFolder Express"

        expect(page).to have_current_path(root_path)
      end
    end
  end

  context "When VVA returns an error" do
    before do
      allow(Fakes::VVAService).to receive(:v2_fetch_documents_for).and_raise(VVA::ClientError)
    end

    scenario "Download with VVA connection error" do
      perform_enqueued_jobs do
        visit "/"
        fill_in "Search for a Veteran ID number below to get started.", with: veteran_id
        click_button "Search"

        expect(page).to have_css ".usa-alert-heading", text: "We are having trouble connecting to VVA"
        click_link "Back to eFolder Express"

        expect(page).to have_current_path(root_path)
      end
    end
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

  context "When at least one document fails" do
    before do
      allow(Fakes::DocumentService).to receive(:v2_fetch_document_file) do |arg|
        case arg.id
        when 1
          raise VBMS::ClientError
        else
          "Test content"
        end
      end
    end

    scenario "Download the eFolder anyway" do
      perform_enqueued_jobs do
        visit "/"
        fill_in "Search for a Veteran ID number below to get started.", with: veteran_id

        click_button "Search"

        expect(page).to have_content "STAN LEE VETERAN ID #{veteran_id}"
        expect(page).to have_content "Start retrieving efolder"

        within(".cf-app-segment--alt") do
          click_button "Start retrieving efolder"
        end

        expect(page).to have_css ".cf-tab.cf-active", text: "Completed (1)"
        expect(page).to have_content "Some files could not be retrieved"

        expect(page).to have_content Caseflow::DocumentTypes::TYPES[documents[1].type_id]

        # Clicking on progress shouldn't change tabs since there number is 0.
        click_on "Progress (0)"
        expect(page).to have_content Caseflow::DocumentTypes::TYPES[documents[1].type_id]

        click_on "Errors (1)"
        expect(page).to have_content Caseflow::DocumentTypes::TYPES[documents[0].type_id]

        within first(".usa-alert-body") do
          click_on "Download anyway"
        end
        expect(page).to have_selector("#confirm-download-anyway")

        within first(".cf-modal-body") do
          click_on "Download anyway"
        end

        DownloadHelpers.wait_for_download
        download = DownloadHelpers.downloaded?
        expect(download).to be_truthy

        expect(DownloadHelpers.download).to include("Lee, Stan - 2222")

        click_on "Start over"

        history_row = "#download-1"

        expect(find(history_row)).to have_content(veteran_id)
        expect(find(history_row)).to have_css(".cf-icon-alert")
        within(history_row) { click_on("View results") }
        expect(page).to have_content("Download anyway")
      end
    end

    scenario "Retrying to download error-ed document succeeds" do
      perform_enqueued_jobs do
        visit "/"
        fill_in "Search for a Veteran ID number below to get started.", with: veteran_id

        click_button "Search"

        expect(page).to have_content "STAN LEE VETERAN ID #{veteran_id}"
        expect(page).to have_content "Start retrieving efolder"

        within(".cf-app-segment--alt") do
          click_button "Start retrieving efolder"
        end

        expect(page).to have_css ".cf-tab.cf-active", text: "Completed (1)"
        expect(page).to have_content "Some files could not be retrieved"

        allow(Fakes::DocumentService).to receive(:v2_fetch_document_file).and_return("Test content")
        within first(".usa-alert-body") do
          click_on "Retry missing files"
        end
        expect(page).to have_content("Success!")
      end
    end
  end
end
