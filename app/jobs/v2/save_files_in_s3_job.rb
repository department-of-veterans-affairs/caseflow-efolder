class V2::SaveFilesInS3Job < ApplicationJob
  queue_as :low_priority

  def perform(manifest_source)
    Raven.extra_context(manifest_source: manifest_source.id)

    manifest_source.records.each(&:fetch!)
  end

  def max_attempts
    1
  end
end
