# frozen_string_literal: true

class V2::SaveFilesInS3Job < ApplicationJob
  queue_as :default

  def perform(manifest_source)
    manifest_source.records.each(&:fetch!)
  end

  def max_attempts
    1
  end
end
