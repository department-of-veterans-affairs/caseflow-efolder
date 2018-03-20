class AlertStuckManifestSourceJob < ApplicationJob
  queue_as :default

  def perform
    if Date.current >= Date.new(2018, 5, 31)
      # Remove the associated entry in config/sidekiq_cron.yml as well.
      ExceptionLogger.capture("Consider removing the AlertStuckManifestSourceJob if we haven't seen a stuck ManifestSource in a while")
    end

    stuck_manifest_ids = ManifestSource.where(status: 1).where("updated_at < ?", 1.day.ago).pluck(:id)

    unless stuck_manifest_ids.empty?
      msg = format(
        "%<count>d ManifestSources with the following IDs have been stuck in the pending state for more than 1 day: %<ids>s. Investigate! %<url>s",
        count: stuck_manifest_ids.length,
        ids: stuck_manifest_ids.join(", "),
        url: "https://github.com/department-of-veterans-affairs/caseflow-efolder/issues/945"
      )
      ExceptionLogger.capture(msg)
    end
  end
end
