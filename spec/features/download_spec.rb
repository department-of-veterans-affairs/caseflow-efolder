require "rails_helper"

RSpec.feature "Downloads" do
  before do
    @user = User.create(css_id: "123123", station_id: "116")
    @user_download = Download.where(user: @user)
    allow(GetDownloadManifestJob).to receive(:perform_later)
    allow(GetDownloadFilesJob).to receive(:perform_later)
    User.authenticate!
    Download.bgs_service = Fakes::BGSService
  end

  scenario "Not login bounces to login page" do
    User.unauthenticate!

    visit("/")
    expect(page).to have_content("Test VA Saml")
    fill_in "Email:", with: "xyz@va.gov"
    click_on "Sign In"

    puts page.current_path
    expect(page).to have_current_path(root_path)
  end

  scenario "Logging out" do
    User.unauthenticate!

    visit("/")
    fill_in "Email:", with: "xyz@va.gov"
    click_on "Sign In"

    click_on "First Last"
    click_on "Sign out"
    expect(page).to have_content("Test VA Saml")
  end

  scenario "Creating a download" do
    Fakes::BGSService.veteran_info = {
      "1234" => {
        "veteran_first_name" => "Stan",
        "veteran_last_name" => "Lee",
        "veteran_last_four_ssn" => "2222"
      }
    }

    visit "/"
    expect(page).to_not have_content "Recent Searches"

    fill_in "Search for a Veteran ID number below to get started.", with: "1234"
    click_button "Search"

    # Test that Caseflow caches veteran name for a download
    Fakes::BGSService.veteran_info = {}

    @download = @user_download.last
    expect(@download).to_not be_nil
    expect(@download.veteran_name).to eq("Stan Lee")
    expect(@download.veteran_first_name).to eq("Stan")
    expect(@download.veteran_last_name).to eq("Lee")
    expect(@download.veteran_last_four_ssn).to eq("2222")

    expect(page).to have_content "Stan Lee (1234)"
    expect(page).to have_content "We are gathering the list of files in the eFolder now"
    expect(page).to have_current_path(download_path(@download))
    expect(page.evaluate_script("window.DownloadStatus.intervalID")).to be_truthy
    expect(GetDownloadManifestJob).to have_received(:perform_later)

    search = Search.where(user: @user).first
    expect(search).to be_download_created
  end

  scenario "Searching for an errored download tries again" do
    Fakes::BGSService.veteran_info = {
      "5555" => {
        "veteran_first_name" => "Stan",
        "veteran_last_name" => "Lee",
        "veteran_last_four_ssn" => "2222"
      }
    }

    @user_download.create!(
      file_number: "5555",
      status: :no_documents
    )

    visit "/"
    fill_in "Search for a Veteran ID number below to get started.", with: "5555"
    click_button "Search"

    expect(page).to have_content "We are gathering the list of files in the eFolder now"
  end

  scenario "Searching for a completed download" do
    @user_download.create!(
      file_number: "5555",
      status: :complete_success
    )

    visit "/"
    fill_in "Search for a Veteran ID number below to get started.", with: "5555"
    click_button "Search"

    expect(page).to have_content("Success")

    search = Search.where(user: @user).first
    expect(search).to be_download_found
  end

  scenario "Extraneous spaces in search input" do
    Fakes::BGSService.veteran_info = {
      "1234" => {
        "veteran_first_name" => "Stan",
        "veteran_last_name" => "Lee",
        "veteran_last_four_ssn" => "2222"
      }
    }

    visit "/"
    expect(page).to_not have_content "Recent Searches"

    fill_in "Search for a Veteran ID number below to get started.", with: " 1234 "
    click_button "Search"

    download = @user_download.last
    expect(download).to_not be_nil

    expect(page).to have_content "Stan Lee (1234)"
  end

  scenario "Requesting non-existent case" do
    visit "/"

    fill_in "Search for a Veteran ID number below to get started.", with: "abcd"
    click_button "Search"

    search = Search.where(user: @user).first
    expect(search).to be_veteran_not_found
    expect(page).to have_content(search.file_number)
  end

  scenario "Using demo mode" do
    expect(DemoGetDownloadManifestJob).to receive(:perform_later)

    visit "/"

    fill_in "Search for a Veteran ID number below to get started.", with: "DEMO123"
    click_button "Search"

    download = @user_download.last
    expect(download).to_not be_nil
    expect(download.veteran_name).to eq("Test User")
    expect(download.veteran_first_name).to eq("Test")
    expect(download.veteran_last_name).to eq("User")
    expect(download.veteran_last_four_ssn).to eq("1224")

    expect(page).to have_content "Test User (DEMO123)"
  end

  scenario "Sensitive download error" do
    Fakes::BGSService.veteran_info = { "8888" => { "veteran_first_name" => "Nick", "veteran_last_name" => "Saban" } }
    Fakes::BGSService.sensitive_files = { "8888" => true }

    visit "/"
    fill_in "Search for a Veteran ID number below to get started.", with: "8888"
    click_button "Search"
    expect(page).to have_current_path("/downloads")
    expect(page).to have_content("contains sensitive information")

    search = Search.where(user: @user).first
    expect(search).to be_access_denied
  end

  scenario "Attempting to view download created by another user" do
    user = User.create(css_id: "123123", station_id: "222")
    another_user = Download.create!(
      user: user,
      file_number: "22222",
      status: :complete_success
    )

    visit download_path(another_user)
    expect(page).to have_content("search again")
  end

  scenario "Attempting to view expired download fails" do
    expired = @user_download.create!(
      file_number: "78901",
      created_at: 77.hours.ago,
      status: :complete_success
    )

    visit download_path(expired)
    expect(page).to have_content("search again")
  end

  scenario "Download with no documents" do
    download = @user_download.create(status: :no_documents)
    visit download_path(download)

    expect(page).to have_css ".cf-app-msg-screen", text: "No Documents in eFolder"
    expect(page).to have_content download.file_number

    click_on "search again"
    expect(page).to have_current_path(root_path)
  end

  scenario "Download with VBMS connection error" do
    download = @user_download.create(status: :vbms_connection_error)
    visit download_path(download)

    expect(page).to have_css ".usa-alert-heading", text: "Can't connect to VBMS"
    click_on "Try again"
    expect(page).to have_current_path(root_path)
  end

  scenario "Confirming download" do
    Fakes::BGSService.veteran_info = {
      "3456" => {
        "veteran_first_name" => "Steph",
        "veteran_last_name" => "Curry",
        "veteran_last_four_ssn" => "2345"
      }
    }
    download = @user_download.create(file_number: "3456", status: :fetching_manifest)

    visit download_path(download)
    expect(page).to have_content "We are gathering the list of files in the eFolder now..."

    download.update_attributes!(status: :pending_confirmation)
    download.documents.create(vbms_filename: "yawn.pdf", mime_type: "application/pdf",
                              received_at: Time.zone.local(2015, 9, 6), download_status: :pending)
    download.documents.create(vbms_filename: "smiley.pdf", mime_type: "application/pdf",
                              received_at: Time.zone.local(2015, 1, 19), download_status: :pending)
    page.execute_script("window.DownloadStatus.recheck();")

    expect(page).to have_content "eFolder Express found 2 files in eFolder #3456"
    expect(page).to have_content "Steph Curry (3456)"
    expect(page).to have_content "yawn.pdf 09/06/2015"
    expect(page).to have_content "smiley.pdf 01/19/2015"
    expect(page.evaluate_script("window.DownloadStatus.intervalID")).to be_falsey
    first(:button, "Start retrieving eFolder").click

    expect(download.reload).to be_pending_documents
    expect(GetDownloadFilesJob).to have_received(:perform_later)

    expect(page).to have_content("Retrieving Files ...")
  end

  scenario "Download progress shows documents in tabs based on their status" do
    download = @user_download.create(status: :pending_documents)
    download.documents.create(vbms_filename: "yawn.pdf", mime_type: "application/pdf", download_status: :pending)
    download.documents.create(vbms_filename: "smiley.pdf", mime_type: "application/pdf", download_status: :success)
    download.documents.create(
      doc_type: "129",
      document_id: "{1234-1234-1234-5555}",
      mime_type: "application/pdf",
      download_status: :failed
    )

    visit download_path(download)
    expect(page).to have_css ".cf-tab.cf-active", text: "Progress (1)"
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
  end

  scenario "Completed with at least one failed document download" do
    download = @user_download.create(file_number: "12", status: :pending_documents)
    download.documents.create(vbms_filename: "roll.pdf", mime_type: "application/pdf", download_status: :failed)
    download.documents.create(vbms_filename: "tide.pdf", mime_type: "application/pdf", download_status: :success)

    visit download_path(download)
    expect(page).to have_css ".cf-tab.cf-active", text: "Progress (0)"

    download.update_attributes(status: :complete_with_errors)
    page.execute_script("window.DownloadProgress.reload();")
    expect(page).to have_css ".cf-tab.cf-active", text: "Completed (1)"
    expect(page).to have_button "Progress (0)", disabled: true
    expect(page).to have_content "Some files couldn't be added"

    click_on "Search for another eFolder"
    expect(page).to have_current_path(root_path)
  end

  scenario "Downloading anyway with at least one failed document download" do
    download = @user_download.create(file_number: "12", status: :pending_documents)
    download.documents.create(vbms_filename: "roll.pdf", mime_type: "application/pdf", download_status: :failed)
    download.documents.create(vbms_filename: "tide.pdf", mime_type: "application/pdf", download_status: :success)

    visit download_path(download)
    expect(page).to have_css ".cf-tab.cf-active", text: "Progress (0)"

    download.update_attributes(status: :complete_with_errors)
    page.execute_script("window.DownloadProgress.reload();")

    expect(page).to have_content "tide.pdf"
    expect(page).to have_content "Download anyway"
    expect(page).to have_no_content "Download incomplete eFolder?"

    within first(".usa-alert-body") do
      click_on "Download anyway"
    end
    expect(page).to have_selector('#confirm-download-anyway')

    click_on "Go back"
  end

  scenario "Retry failed download" do
    download = @user_download.create(file_number: "12", status: :complete_with_errors)
    download.documents.create(vbms_filename: "roll.pdf", mime_type: "application/pdf", download_status: :failed)
    download.documents.create(vbms_filename: "tide.pdf", mime_type: "application/pdf", download_status: :success)

    visit download_path(download)
    click_on "Try retrieving eFolder again"

    expect(page).to have_css ".cf-tab.cf-active", text: "Progress (2)"
    expect(page).to have_content "Completed (0)"
    expect(page).to have_content "Errors (0)"
    expect(GetDownloadFilesJob).to have_received(:perform_later)
  end

  scenario "Download non-existing zip" do
    fake_id = "non_existing_download_id"
    expect(Download.where(id: fake_id)).to be_empty

    visit download_download_path(fake_id)
    expect(page.status_code).to be(404)
  end

  scenario "Completed download" do
    Fakes::BGSService.veteran_info = {
      "12" => {
        "veteran_first_name" => "Stan",
        "veteran_last_name" => "Lee",
        "veteran_last_four_ssn" => "2222"
      }
    }
    # clean files
    FileUtils.rm_rf(Rails.application.config.download_filepath)

    @download = @user_download.create(file_number: "12", status: :complete_success)
    @download.documents.create(received_at: Time.zone.now, doc_type: "102", mime_type: "application/pdf")
    @download.documents.create(received_at: Time.zone.now, doc_type: "103", mime_type: "application/pdf")

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

    first(:link, "Download eFolder").click
    expect(page.response_headers["Content-Type"]).to eq("application/zip")
  end

  scenario "Recent download list expires old downloads" do
    @user_download.create!(
      file_number: "78901",
      created_at: 77.hours.ago,
      status: :complete_success
    )

    visit "/"
    expect(page).to_not have_content("78901")
  end

  scenario "Recent download list" do
    pending_confirmation = @user_download.create!(
      file_number: "12345",
      status: :pending_confirmation
    )
    pending_documents = @user_download.create!(
      file_number: "45678",
      status: :pending_documents
    )
    complete = @user_download.create!(
      file_number: "78901",
      status: :complete_success
    )
    complete_with_errors = @user_download.create!(
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
    expect(page).to have_content("Download eFolder")

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
end
