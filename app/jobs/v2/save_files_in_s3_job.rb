class V2::SaveFilesInS3Job < ActiveJob::Base
  queue_as :default

  def perform(manifest_source)
    manifest_source.records.each do |record|
      record.fetch! unless record.pending?
    end
  end

  def max_attempts
    1
  end
end
