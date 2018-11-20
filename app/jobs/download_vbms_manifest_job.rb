# class DownloadVBMSManifestJob < DownloadManifestJob
#   queue_as :high_priority

#   def get_service(_download)
#     VBMSService
#   end

#   def service_name
#     "vbms"
#   end

#   def client_error
#     VBMS::ClientError
#   end
# end
