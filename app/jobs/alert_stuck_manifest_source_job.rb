class AlertStuckManifestSourceJob < ApplicationJob
  queue_as :default

  def perform
    if Date.current >= Date.new(2018, 5, 31)
      # Remove the associate entry in config/sidekiq_cron.yml as well.
      ExceptionLogger.capture("Consider removing the AlertStuckManifestSourceJob if we haven't seen a stuck ManifestSource in a while")
    end

    stuck_manifest_ids = ManifestSource.find_by_sql("select * from manifest_sources where status = 1 and created_at + interval '1 day' < current_timestamp").map(&:id)

    unless stuck_manifest_ids.empty?
      msg = format(
        "%<count>d ManifestSources with the following IDs have been stuck in the pending state for more than 1 day: %<ids>s",
        count: stuck_manifest_ids.length,
        ids: stuck_manifest_ids.join(", ")
      )
      ExceptionLogger.capture(msg)
    end
  end
end
