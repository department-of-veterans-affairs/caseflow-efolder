require "rails_helper"

RSpec.feature "Downloads" do
	scenario "Creating a download" do
		visit '/'
		fill_in "File Number", :with => '1234'
		click_button "Download"

		@download = Download.last
		expect(@download).to_not be_nil

		expect(page).to have_content 'Fetching eFolder document manifest'
		expect(page).to have_current_path(download_path(@download))
	end

	scenario "Download with no documents" do
		@download = Download.create(status: :no_documents)
		visit download_url(@download)

		expect(page).to have_css ".usa-alert-error", text: "no documents"
	end
end