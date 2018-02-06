class GuiController < ApplicationController
  before_action :authorize

  def react
    if can_access_react_app?
      render "_react", layout: false
    else
      redirect_to "/"
    end
  end

  def initial_react_data
    {
      csrfToken: form_authenticity_token,
      dropdownUrls: dropdown_urls,
      efolderAccessImagePath: ActionController::Base.helpers.image_path("help/efolder-access.png"),
      feedbackUrl: feedback_url,
      recentDownloads: recent_downloads.sort_by(&:created_at).reverse,
      referenceGuidePath: ActionController::Base.helpers.asset_path("reference_guide.pdf"),
      trainingGuidePath: ActionController::Base.helpers.asset_path("training_guide.pdf"),
      userDisplayName: current_user.display_name
    }.to_json
  end
  helper_method :initial_react_data

  def dropdown_urls
    [
      {
        title: "Help",
        link: url_for(controller: "/help", action: "show")
      },
      {
        title: "Send Feedback",
        link: feedback_url,
        target: "_blank"
      },
      {
        title: "Sign out",
        link: url_for(controller: "/sessions", action: "destroy")
      }
    ]
  end

  def can_access_react_app?
    FeatureToggle.enabled?(:efolder_react_app, user: current_user) || Rails.env.development?
  end

  private

  def downloads
    Download.active.where(user: current_user)
  end

  # TODO: This will need to be replaced by a similar function for UserManifests
  # efolder issue 813 addresses this requirement.
  def recent_downloads
    @recent_downloads ||= downloads.where(status: [3, 4, 5, 6])
  end
end
