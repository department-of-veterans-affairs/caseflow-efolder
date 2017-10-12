class DownloadVBMSManifestJob < DownloadManifestJob
  queue_as :default

  def service(_download)
    VBMSService
  end

  def service_name
    "vbms"
  end
end
