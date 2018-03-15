require "rails_helper"
# require "sidekiq/testing"

RSpec.feature "Downloads" do
  include ActiveJob::TestHelper
  # include Caseflow::DocumentTypes

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

    DownloadHelpers.clear_downloads
  end

  after do
    FeatureToggle.disable!(:efolder_react_app)
  end

  let(:root_path) { "/" }

  let(:invalid_veteran_id) {"abcd"}

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

    it "coachmarks are not displayed indicating that we are viewing the react app" do
      visit "/"
      expect(page).to_not have_content("See what's new!")
    end
  end

  scenario "Download coachmarks" do
    def assert_coachmark_exists
      expect(page).to have_content("Downloads from eFolder Express now include Virtual VA documents.")
    end

    def assert_coachmark_does_not_exist
      expect(page).to_not have_content("Downloads from eFolder Express now include Virtual VA documents.")
    end

    visit "/"
    assert_coachmark_exists
    click_on "Close"
    assert_coachmark_does_not_exist
    click_on "See what's new!"
    assert_coachmark_exists
    click_on "Hide tutorial"
    assert_coachmark_does_not_exist
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

      within(".cf-app-segment--alt") do
        click_button "Download efolder"
      end

      DownloadHelpers.wait_for_download
      download = DownloadHelpers.downloaded?
      expect(download).to be_truthy

      expect(DownloadHelpers.download).to include("Lee, Stan - 2222.zip")
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
    binding.pry

    expect(page).to have_content("File number is invalid")
  end

  # TODO
  # scenario "Requesting veteran that does not exist" do
  #   visit "/"

  #   fill_in "Search for a Veteran ID number below to get started.", with: "88888888"
  #   click_button "Search"

  #   search = Search.where(user: @user).first
  #   expect(search).to be_veteran_not_found
  # end

  # TODO: Fix test
  context "When veteran id has high sensitivity" do
    before do
      allow_any_instance_of(Fakes::BGSService).to receive(:sensitive_files).and_return({ veteran_id => true })
    end

    scenario "Cannot access it" do
      visit "/"
      fill_in "Search for a Veteran ID number below to get started.", with: veteran_id
      click_button "Search"

      expect(page).to have_current_path("/")
      expect(page).to have_content("contains sensitive information")
    end
  end

  # TODO
  # scenario "Attempting to view expired download fails" do
  #   expired = @user_manifest.create!(
  #     file_number: "78901",
  #     created_at: 77.hours.ago,
  #     status: :complete_success
  #   )

  #   visit download_path(expired)
  #   expect(page).to have_content("search again")
  # end


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

    scenario "Download with VBMS connection error", focus: true do
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

    scenario "Download with VVA connection error", focus: true do
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

  scenario "Confirming download" do
    veteran_info = {
      "3456" => {
        "veteran_first_name" => "Steph",
        "veteran_last_name" => "Curry",
        "veteran_last_four_ssn" => "2345"
      }
    }
    allow_any_instance_of(Fakes::BGSService).to receive(:veteran_info).and_return(veteran_info)
    download = @user_manifest.create(file_number: "3456", status: :fetching_manifest)

    visit download_path(download)
    expect(page).to have_content "We are gathering the list of files in the eFolder now..."

    download.reload.update_attributes!(status: :pending_confirmation)
    download.documents.create(vbms_filename: "yawn.pdf", mime_type: "application/pdf",
                              received_at: Time.zone.local(2015, 9, 6), download_status: :pending)
    download.documents.create(vbms_filename: "smiley.pdf", mime_type: "application/pdf",
                              received_at: Time.zone.local(2015, 1, 19), download_status: :pending)
    page.execute_script("window.DownloadStatus.recheck();")

    expect(page).to have_content "found a total of 2 documents"
    expect(page).to have_content "STEPH CURRY VETERAN ID 3456"
    expect(page).to have_content "yawn.pdf VBMS 09/06/2015"
    expect(page).to have_content "smiley.pdf VBMS 01/19/2015"

    expect(page).to have_content(
      "The total number of documents that will be retrieved from each database is listed here."
    )
    expect(page).to have_content(
      "The Source column shows the name of the database from which the file will be retrieved."
    )

    expect(page.evaluate_script("window.DownloadStatus.intervalID")).to be_falsey
    first(:button, "Start retrieving efolder").click

    expect(download.reload).to be_pending_documents
    expect(DownloadFilesJob).to have_received(:perform_later)

    expect(page).to have_content("Retrieving Files ...")
  end

  scenario "Download progress shows correct information" do
    download = @user_manifest.create(status: :pending_documents)
    download.documents.create(
      vbms_filename: "yawn.pdf",
      mime_type: "application/pdf",
      started_at: 1.minute.ago,
      download_status: :pending
    )
    download.documents.create(
      vbms_filename: "yawn.pdf",
      mime_type: "application/pdf",
      started_at: 1.minute.ago,
      download_status: :pending
    )
    download.documents.create(
      vbms_filename: "smiley.pdf",
      mime_type: "application/pdf",
      started_at: 2.minutes.ago,
      completed_at: 1.minute.ago,
      download_status: :success
    )
    download.documents.create(
      type_id: "129",
      document_id: "{1234-1234-1234-5555}",
      mime_type: "application/pdf",
      started_at: 2.minutes.ago,
      download_status: :failed
    )

    visit download_path(download)
    expect(page).to have_css ".cf-tab.cf-active", text: "Progress (2)"
    expect(page).to have_css ".document-pending", text: "yawn.pdf"
    expect(page).to_not have_css ".document-success", text: "smiley.pdf"
    expect(page).to_not have_css ".document-failed", text: "poo.pdf"

    click_on "Completed"
    expect(page).to have_css ".cf-tab.cf-active", text: "Completed (1)"
    expect(page).to have_css ".document-success", text: "smiley.pdf"
    expect(page).to_not have_css ".document-pending", text: "yawn.pdf"
    expect(page).to_not have_css ".document-failed", text: "poo.pdf"

    click_on "Errors"
    expect(page).to have_css ".cf-tab.cf-active", text: "Errors (1)"
    expect(page).to have_css ".document-failed", text: "VA 21-509 Statement of Dependency of Parents 1234-1234-1234-5555"
    expect(page).to_not have_css ".document-success", text: "smiley.pdf"
    expect(page).to_not have_css ".document-pending", text: "yawn.pdf"

    expect(page).to have_content "2 of 4 files remaining"
  end

  scenario "Completed with at least one failed document download" do
    download = @user_manifest.create(file_number: "12", status: :pending_documents)
    download.documents.create(vbms_filename: "roll.pdf", mime_type: "application/pdf", download_status: :failed)
    download.documents.create(vbms_filename: "tide.pdf", mime_type: "application/pdf", download_status: :success)

    visit download_path(download)
    expect(page).to have_css ".cf-tab.cf-active", text: "Progress (0)"

    # If this test scenario is run after another scenario where a download_url for a download with the same ID as this
    # download, capybara will not make the request to /downloads/1 (for example), and will instead serve the webdriver's
    # cached version of that page. However, when this test scenario is run and no cached versions of the page exist
    # DownloadsController.start_download_files() will update the download's updated_at value in the database causing a
    # StaleObjectError when we attempt to update the status below. Re-fetch the download record from the database after
    # we have updated the updated_at value in order to avoid this error.
    download = Download.find(download.id)

    download.update_attributes(status: :complete_with_errors)
    page.execute_script("window.DownloadProgress.reload();")
    expect(page).to have_css ".cf-tab.cf-active", text: "Completed (1)"
    expect(page).to have_button "Progress (0)", disabled: true
    expect(page).to have_content "Some files couldn't be added"

    click_on "Search for another efolder"
    expect(page).to have_current_path(root_path)
  end

  scenario "Downloading anyway with at least one failed document download" do
    download = @user_manifest.create(file_number: "12", status: :pending_documents)
    download.documents.create(vbms_filename: "roll.pdf", mime_type: "application/pdf", download_status: :failed)
    download.documents.create(vbms_filename: "tide.pdf", mime_type: "application/pdf", download_status: :success)

    visit download_path(download)
    expect(page).to have_css ".cf-tab.cf-active", text: "Progress (0)"

    download = Download.find(download.id)

    download.update_attributes(status: :complete_with_errors)
    page.execute_script("window.DownloadProgress.reload();")

    expect(page).to have_content "tide.pdf"
    expect(page).to have_content "Download anyway"
    expect(page).to have_no_content "Download incomplete eFolder?"

    within first(".usa-alert-body") do
      click_on "Download anyway"
    end
    expect(page).to have_selector("#confirm-download-anyway")

    click_on "Go back"
  end

  scenario "Retry failed download" do
    download = @user_manifest.create(file_number: "12", status: :complete_with_errors)
    download.documents.create(vbms_filename: "roll.pdf", mime_type: "application/pdf", download_status: :failed)
    download.documents.create(vbms_filename: "tide.pdf", mime_type: "application/pdf", download_status: :success)

    visit download_path(download)
    click_on "Try retrieving efolder again"

    expect(page).to have_css ".cf-tab.cf-active", text: "Progress (2)"
    expect(page).to have_content "Completed (0)"
    expect(page).to have_content "Errors (0)"
    expect(DownloadFilesJob).to have_received(:perform_later)
  end

  scenario "Download non-existing zip" do
    fake_id = "non_existing_download_id"
    expect(Download.where(id: fake_id)).to be_empty

    visit download_download_path(fake_id)
    expect(page).to have_content("Something went wrong...")
  end

  scenario "Completed download" do
    veteran_info = {
      "12" => {
        "veteran_first_name" => "Stan",
        "veteran_last_name" => "Lee",
        "veteran_last_four_ssn" => "2222"
      }
    }
    allow_any_instance_of(Fakes::BGSService).to receive(:veteran_info).and_return(veteran_info)
    # clean files
    FileUtils.rm_rf(Rails.application.config.download_filepath)

    @download = @user_manifest.create(file_number: "12", status: :complete_success)
    @download.documents.create(received_at: Time.zone.now, type_id: "102", mime_type: "application/pdf")
    @download.documents.create(received_at: Time.zone.now, type_id: "103", mime_type: "application/pdf")

    class FakeVBMSService
      def self.fetch_document_file(_document)
        IO.binread(Rails.root + "spec/support/test.pdf")
      end
    end

    download_documents = DownloadDocuments.new(download: @download, vbms_service: FakeVBMSService)
    download_documents.create_documents
    download_documents.download_and_package

    visit download_path(@download)
    expect(page).to have_css ".document-success", text: "VA 119 Report of Contact"
    expect(page).to have_css ".document-success", text: "VA 5655 Financial Status Report (Submit with Waiver Request)"

    def expect_page_to_have_coachmarks
      expect(page).to have_content(
        "The total number of documents that will be downloaded from each database is listed here."
      )
      expect(page).to have_content("Hide tutorial")
    end

    def expect_page_to_not_have_coachmarks
      expect(page).to_not have_content(
        "The total number of documents that will be downloaded from each database is listed here."
      )
      expect(page).to have_content(
        "See what's new!"
      )
    end

    expect_page_to_have_coachmarks

    DownloadHelpers.clear_downloads
    first(:link, "Download efolder").click
    DownloadHelpers.wait_for_download
    expect(DownloadHelpers.filesize).to eq(File.size(download_documents.zip_path))
    DownloadHelpers.clear_downloads

    visit download_path(@download)
    expect_page_to_have_coachmarks

    # After visiting the download page 3 times, we no longer want the coachmarks to show up automatically.
    visit download_path(@download)
    expect_page_to_not_have_coachmarks

    click_on "See what's new!"
    expect_page_to_have_coachmarks

    click_on "Hide tutorial"
    expect_page_to_not_have_coachmarks

    click_on "See what's new!"
    expect_page_to_have_coachmarks

    # When we click on "See what's new", we want the coachmarks to show up on subsequent page loads.
    visit "/"
    expect(page).to have_content("Downloads from eFolder Express now include Virtual VA documents.")
    expect(page).to have_content("Hide tutorial")
  end

  scenario "Recent download list expires old downloads" do
    @user_manifest.create!(
      file_number: "78901",
      created_at: 77.hours.ago,
      status: :complete_success
    )

    visit "/"
    expect(page).to_not have_content("78901")
  end

  scenario "Recent download list" do
    pending_confirmation = @user_manifest.create!(
      file_number: "12345",
      status: :pending_confirmation
    )
    pending_documents = @user_manifest.create!(
      file_number: "45678",
      status: :pending_documents
    )
    complete = @user_manifest.create!(
      file_number: "78901",
      status: :complete_success
    )
    complete_with_errors = @user_manifest.create!(
      file_number: "78902",
      status: :complete_with_errors
    )
    another_user = Download.create!(
      user: User.create(css_id: "456", station_id: "45673"),
      file_number: "22222",
      status: :complete_success
    )

    visit "/"

    expect(page).to_not have_content(pending_confirmation.file_number)
    expect(page).to_not have_content(another_user.file_number)

    complete_with_errors_row = "#download-#{complete_with_errors.id}"
    expect(find(complete_with_errors_row)).to have_content("78902")
    expect(find(complete_with_errors_row)).to have_css(".cf-icon-alert")
    within(complete_with_errors_row) { click_on("View results") }
    expect(page).to have_content("Download efolder")

    visit "/"
    pending_documents_row = "#download-#{pending_documents.id}"
    expect(find(pending_documents_row)).to have_content("45678")
    within(pending_documents_row) { click_on("View progress") }
    expect(page).to have_current_path(download_path(pending_documents))

    visit "/"
    complete_row = "#download-#{complete.id}"
    expect(find(complete_row)).to have_content("78901")
    within(complete_row) { click_on("View results") }
    expect(page).to have_current_path(download_path(complete))
  end

  # route should only be available to test user anyway
  scenario "unable to access delete download cache" do
    ENV["TEST_USER_ID"] = nil
    Download.create!(
      user: @user,
      file_number: "321321",
      status: :complete_success
    )

    visit "/"
    expect(page).to have_content("View results")
    expect(page).not_to have_content("Delete Cache")
  end

  scenario "test user able to access delete download cache" do
    ENV["TEST_USER_ID"] = "321321"
    Download.create!(
      user: User.create(css_id: ENV["TEST_USER_ID"], station_id: "116"),
      file_number: "321321",
      status: :complete_success
    )
    User.tester!

    visit "/"
    expect(page).to have_content("View results")
    expect(page).to have_content("Delete Cache")
    click_on("Delete Cache")
    expect(page).not_to have_content("View results")
  end
end
