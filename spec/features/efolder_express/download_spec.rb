require "rails_helper"

RSpec.feature "Downloads" do
	scenario "Creating a download" do
		visit '/'
		fill_in "File Number", :with => '1234'
		click_button "Download"

		download = Download.last
		expect(download).to_not be_nil

		expect(page).to have_content 'Starting Download'
		expect(page).to have_current_path(status_download_path(download))
	end
end