class V2::SaveFilesInS3Job < ActiveJob::Base
  queue_as :low_priority

  def perform(manifest_source)
    puts "start V2::SaveFilesInS3Job for #{manifest_source.name}"
    manifest_source.records.each(&:fetch!)
  end

  def max_attempts
    1
  end
end
