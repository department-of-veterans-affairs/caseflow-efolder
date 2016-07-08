require "rails_helper"

RSpec.feature "Downloads" do
  before do
    @user_download = Download.where(
      user_station_id: "116",
      user_id: "123123"
    )
    Download.delete_all
    Document.delete_all
    allow(GetDownloadManifestJob).to receive(:perform_later)
    allow(GetDownloadFilesJob).to receive(:perform_later)

    Download.bgs_service = Fakes::BGSService
  end

  scenario "Creating a download" do
    Fakes::BGSService.veteran_names = { "1234" => "Stan Lee" }

    visit "/"
    expect(page).to_not have_content "Recent Searches"

    fill_in "Search for a VBMS eFolder to get started.", with: "1234"
    click_button "Search"

    @download = @user_download.last
    expect(@download).to_not be_nil

    expect(page).to have_content "Stan Lee (1234)"
    expect(page).to have_content "We are gathering the list of files in the eFolder now"
    expect(page).to have_current_path(download_path(@download))
    expect(GetDownloadManifestJob).to have_received(:perform_later)
  end

  scenario "Trim search input" do
    Fakes::BGSService.veteran_names = { "1234" => "Stan Lee" }

    visit "/"
    expect(page).to_not have_content "Recent Searches"

    fill_in "Search for a VBMS eFolder to get started.", with: " 1234 "
    click_button "Search"

    @download = @user_download.last
    expect(@download).to_not be_nil

    expect(page).to have_content "Stan Lee (1234)"
  end

  scenario "Sensitive download error" do
    Fakes::BGSService.veteran_names = { "8888" => "Nick Saban" }
    Fakes::BGSService.sensitive_files = { "8888" => true }

    visit "/"
    fill_in "Search for a VBMS eFolder to get started.", with: "8888"
    click_button "Search"
    expect(page).to have_current_path("/downloads")
    expect(page).to have_content("contains sensitive information")
  end

  scenario "Attempting to view download created by another user" do
    another_user = Download.create!(
      user_station_id: "222",
      user_id: "123123",
      file_number: "22222",
      status: :complete
    )

    visit download_path(another_user)
    expect(page).to have_content("not found")
  end

  scenario "Download with no documents" do
    @download = @user_download.create(status: :no_documents)
    visit download_path(@download)

    expect(page).to have_css ".usa-alert-error", text: "Couldn't find documents in eFolder"

    click_on "Try Again"
    expect(page).to have_current_path(root_path)
  end

  scenario "Confirming download" do
    @download = @user_download.create(file_number: "3456", status: :fetching_manifest)

    visit download_path(@download)
    expect(page).to have_content "We are gathering the list of files in the eFolder now..."

    @download.update_attributes!(status: :pending_confirmation)
    @download.documents.create(vbms_filename: "yawn.pdf", mime_type: "application/pdf",
                               received_at: Time.zone.local(2015, 9, 6), download_status: :pending)
    @download.documents.create(vbms_filename: "smiley.pdf", mime_type: "application/pdf",
                               received_at: Time.zone.local(2015, 1, 19), download_status: :pending)
    page.execute_script("window.DownloadStatus.recheck();")

    expect(page).to have_content "eFolder Express found 2 files in eFolder #3456"
    expect(page).to have_content "yawn.pdf 09/06/2015"
    expect(page).to have_content "smiley.pdf 01/19/2015"
    click_on "Fetch Files from VBMS"

    expect(@download.reload).to be_pending_documents
    expect(GetDownloadFilesJob).to have_received(:perform_later)

    expect(page).to have_content("Fetching Files")
  end

  scenario "Unfinished download with documents" do
    @download = @user_download.create(status: :pending_documents)
    @download.documents.create(vbms_filename: "yawn.pdf", mime_type: "application/pdf", download_status: :pending)
    @download.documents.create(vbms_filename: "poo.pdf", mime_type: "application/pdf", download_status: :failed)
    @download.documents.create(vbms_filename: "smiley.pdf", mime_type: "application/pdf", download_status: :success)

    visit download_path(@download)
    expect(page).to have_css ".document-success", text: "smiley.pdf"
    expect(page).to have_css ".document-pending", text: "yawn.pdf"
    expect(page).to have_css ".document-failed", text: "poo.pdf"
  end

  scenario "Completed with at least one failed document download" do
    @download = @user_download.create(file_number: "12", status: :complete)
    @download.documents.create(vbms_filename: "roll.pdf", mime_type: "application/pdf", download_status: :failed)
    @download.documents.create(vbms_filename: "tide.pdf", mime_type: "application/pdf", download_status: :success)

    visit download_path(@download)

    expect(page).to have_content "Trouble Fetching Files"

    click_on "Search for Another eFolder"
    expect(page).to have_current_path(root_path)
  end

  scenario "Completed download" do
    # clean files
    FileUtils.rm_rf(Rails.application.config.download_filepath)

    @download = @user_download.create(file_number: "12", status: :complete)
    @download.documents.create(vbms_filename: "roll.pdf", mime_type: "application/pdf")
    @download.documents.create(vbms_filename: "tide.pdf", mime_type: "application/pdf")

    class FakeVBMSService
      def self.fetch_document_file(_document)
        "this is some document, woah!"
      end
    end

    download_documents = DownloadDocuments.new(download: @download, vbms_service: FakeVBMSService)
    download_documents.create_documents
    download_documents.download_and_package

    visit download_path(@download)
    expect(page).to have_css ".document-success", text: "roll.pdf"
    expect(page).to have_css ".document-success", text: "tide.pdf"

    click_on "Download Zip"
    expect(page.response_headers["Content-Type"]).to eq("application/zip")

    visit "/"
    within("#download-#{@download.id}") { click_on("Download Zip") }
    expect(page.response_headers["Content-Type"]).to eq("application/zip")
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
      status: :complete
    )
    another_user = Download.create!(
      user_station_id: "222",
      user_id: "123123",
      file_number: "22222",
      status: :complete
    )

    visit "/"

    expect(page).to_not have_content(pending_confirmation.file_number)

    expect(page).to_not have_content(another_user.file_number)

    pending_documents_row = "#download-#{pending_documents.id}"
    expect(find(pending_documents_row)).to have_content("45678")
    expect(find(pending_documents_row)).to have_content("Downloading...")
    within(pending_documents_row) { click_on("View Results") }
    expect(page).to have_current_path(download_path(pending_documents))

    visit "/"
    complete_row = "#download-#{complete.id}"
    expect(find(complete_row)).to have_content("78901")
    expect(find(complete_row)).to have_content("Download Zip")
  end
end
