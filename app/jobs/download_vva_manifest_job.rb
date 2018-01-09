# frozen_string_literal: true

class DownloadVVAManifestJob < DownloadManifestJob
  queue_as :default

  def get_service(download)
    return nil if !FeatureToggle.enabled?(:vva_service, user: download.user)
    VVAService
  end

  def service_name
    "vva"
  end

  def client_error
    VVA::ClientError
  end
end
