class SaveFilesInS3Job < ActiveJob::Base
  queue_as :default

  def perform(manifest_source)
    manifest.source.records.each do |record|
      record.fetch!
    end
  end

  def max_attempts
    1
  end
end
