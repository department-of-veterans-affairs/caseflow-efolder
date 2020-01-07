require "rails_helper"

feature "ActiveJob Helpers" do
  include ActiveJob::TestHelper

  before do
    @user = User.create(css_id: "123123", station_id: "116")
    User.authenticate!
    DownloadHelpers.clear_downloads
  end

  after do
    DownloadHelpers.clear_downloads
  end

  context "when job is queued" do
    scenario "the job runs" do
      perform_enqueued_jobs do
        visit '/test'
        click_button 'test'

        expect(page).to have_content('file touch queued')

        # first one shows the job ran ok
        DownloadHelpers.wait_for_download
        download = DownloadHelpers.downloaded?
        expect(download).to be_truthy

        expect(DownloadHelpers.download).to eq("touched-file.txt")

        click_button 'download'

        # second one shows the file downloaded ok
        DownloadHelpers.wait_for_download(num: 2)

        expect(DownloadHelpers.downloads).to contain_exactly("touched-file.txt", "touched-file-download.txt")
      end
    end
  end
end
