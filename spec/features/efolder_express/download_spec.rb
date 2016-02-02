require "rails_helper"

RSpec.feature "Downloads" do
  before do
    allow(DownloadFileJob).to receive(:perform_later)
  end

  scenario "Creating a download" do
    visit "/"
    fill_in "File Number", with: "1234"
    click_button "Download"

    @download = Download.last
    expect(@download).to_not be_nil

    expect(page).to have_content 'Downloading File #1234'
    expect(page).to have_content "We are gathering the list of files in the eFolder now"
    expect(page).to have_content "Progress: 20%"
    expect(page).to have_current_path(download_path(@download))
    expect(DownloadFileJob).to have_received(:perform_later)
  end

  scenario "Download with no documents" do
    @download = Download.create(status: :no_documents)
    visit download_url(@download)

    expect(page).to have_css ".usa-alert-error", text: "no documents"

    click_on "Try Again"
    expect(page).to have_current_path(root_path)
  end

  scenario "Unfinished download with documents" do
    @download = Download.create(status: :pending_documents)
    @download.documents.create(filename: "yawn.pdf", download_status: :pending)
    @download.documents.create(filename: "poo.pdf", download_status: :failed)
    @download.documents.create(filename: "smiley.pdf", download_status: :success)

    visit download_url(@download)
    expect(page).to have_css ".document-success", text: "smiley.pdf"
    expect(page).to have_css ".document-pending", text: "yawn.pdf"
    expect(page).to have_css ".document-failed", text: "poo.pdf"
  end

  scenario "Completed with at least one failed document download" do
    @download = Download.create(file_number: "12", status: :complete)
    @download.documents.create(filename: "roll.pdf", download_status: :failed)
    @download.documents.create(filename: "tide.pdf", download_status: :success)

    visit download_url(@download)

    expect(page).to have_content "Some documents failed to download"

    click_on "Try Again"
    expect(page).to have_current_path(root_path)
  end

  scenario "Completed download" do
    # clean files
    FileUtils.rm_rf(Rails.application.config.download_filepath)

    @download = Download.create(file_number: "12", status: :complete)
    @download.documents.create(filename: "roll.pdf")
    @download.documents.create(filename: "tide.pdf")

    class FakeVBMSService
      def self.fetch_document_file(_document)
        "this is some document, woah!"
      end
    end

    download_documents = DownloadDocuments.new(download: @download, vbms_service: FakeVBMSService)
    download_documents.perform

    visit download_url(@download)
    expect(page).to have_css ".document-success", text: "roll.pdf"
    expect(page).to have_css ".document-success", text: "tide.pdf"

    click_on "Download .zip"
    expect(page.response_headers["Content-Type"]).to eq("application/zip")
  end
end
