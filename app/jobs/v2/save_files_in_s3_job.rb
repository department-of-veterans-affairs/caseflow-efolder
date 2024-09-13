class V2::SaveFilesInS3Job < ApplicationJob
  queue_as :low_priority

  def perform(manifest_source, user_id)
    Raven.extra_context(manifest_source: manifest_source.id, user_id: user_id)

    # Set user for permission check if the user is blank
    if FeatureToggle.enabled?(:check_user_sensitivity) && RequestStore[:current_user].blank?
      user = User.find(user_id)
      RequestStore.store[:current_user] = user
    end

    manifest_source.records.each(&:fetch!)
  end

  def max_attempts
    1
  end
end
