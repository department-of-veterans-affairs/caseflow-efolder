require "rails_helper"

RSpec.feature "Downloads" do
  scenario "Creating a download" do
    # expect DownloadFileJob to be performed

    visit '/'
    fill_in "File Number", :with => '1234'
    click_button "Download"

    @download = Download.last
    expect(@download).to_not be_nil

    expect(page).to have_content 'Downloading File #1234'
    expect(page).to have_content 'We are gathering the list of files in the eFolder now'
    expect(page).to have_current_path(download_path(@download))
  end

  scenario "Download with no documents" do
    @download = Download.create(status: :no_documents)
    visit download_url(@download)

    expect(page).to have_css ".usa-alert-error", text: "no documents"
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

  scenario "Completed download" do
    @download = Download.create(status: :complete)
    @download.documents.create(filename: "roll.pdf", download_status: :success)
    @download.documents.create(filename: "tide.pdf", download_status: :success)

    visit download_url(@download)
    expect(page).to have_css ".document-success", text: "roll.pdf"
    expect(page).to have_css ".document-success", text: "tide.pdf"
    expect(page).to have_css ".usa-button", text: "Download .zip"
  end
end