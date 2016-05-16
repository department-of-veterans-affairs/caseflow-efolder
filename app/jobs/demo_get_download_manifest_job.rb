class DemoGetDownloadManifestJob < ActiveJob::Base
  queue_as :default

  def perform(download)
    sleep(3)
    download.update_attributes!(status: :pending_confirmation)

    download.documents.create(filename: "demo1.txt", received_at: 12.days.ago)
    download.documents.create(filename: "demo2.txt", received_at: 6.days.ago)
    download.documents.create(filename: "demo3.txt", received_at: 2.days.ago)
    download.documents.create(filename: "demo4.txt", received_at: 1.days.ago)
  end
end
