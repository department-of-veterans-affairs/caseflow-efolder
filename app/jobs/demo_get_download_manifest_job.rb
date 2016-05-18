class DemoGetDownloadManifestJob < ActiveJob::Base
  queue_as :default

  DEMOS = {
    "DEMO1" => {
      manifest_load: 4,
      num_docs: 50,
      max_file_load: 4
    },
    "DEMO2" => {
      manifest_load: 4,
      num_docs: 100,
      max_file_load: 5
    },
    "DEMO3" => {
      manifest_load: 4,
      num_docs: 100,
      max_file_load: 10,
      error: true
    },
    "DEMO4" => {
      manifest_load: 4,
      num_docs: 400,
      max_file_load: 4
    },
    "DEMODEFAULT" => {
      manifest_load: 4,
      num_docs: 10,
      max_file_load: 3
    }
  }.freeze

  def perform(download)
    demo = DEMOS[download.file_number] || DEMOS["DEMODEFAULT"]
    sleep(demo[:manifest_load])
    create_documents(download, demo[:num_docs])

    download.update_attributes!(status: :pending_confirmation)
  end

  def create_documents(download, number)
    number.times do |i|
      download.documents.create(filename: "happy-thursday-#{SecureRandom.hex}.txt", received_at: (i * 2).days.ago)
    end
  end
end
