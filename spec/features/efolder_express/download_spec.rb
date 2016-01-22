require "rails_helper"

RSpec.feature "Downloads" do
	scenario "Creating a download" do
		visit '/'
		fill_in "File Number", :with => '1234'
		click_button "Download"

		download = Download.last
		expect(download).to_not be_nil

		expect(page).to have_content 'Fetching eFolder document manifest'
		expect(page).to have_current_path(download_path(download))
	end
end