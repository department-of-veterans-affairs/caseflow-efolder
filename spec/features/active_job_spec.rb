require "rails_helper"

feature "ActiveJob Helpers" do
  include ActiveJob::TestHelper

  before do
    @user = User.create(css_id: "123123", station_id: "116")
    User.authenticate!
    DownloadHelpers.clear_downloads
  end

  context "when job is queued" do
    scenario "the job runs" do
      perform_enqueued_jobs do
        visit '/test'
        click_button 'test'

        expect(page).to have_content('file touch queued')

        DownloadHelpers.wait_for_download
        download = DownloadHelpers.downloaded?
        expect(download).to be_truthy

        expect(DownloadHelpers.download).to include("touched-file.txt")
      end
    end
  end
end
