class DownloadVBMSManifestJob < DownloadManifestJob
  queue_as :default

  def service(download)
    VBMSService
  end

  def service_name
    "vbms"
  end

end
