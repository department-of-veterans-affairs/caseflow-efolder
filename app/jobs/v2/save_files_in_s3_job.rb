class V2::SaveFilesInS3Job < ActiveJob::Base
  queue_as :low_priority

  def perform(manifest_source)
    manifest_source.records.each(&:fetch!)
  end

  def max_attempts
    1
  end
end
