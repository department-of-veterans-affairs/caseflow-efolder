# class DownloadAllManifestJob < ApplicationJob
#   queue_as :high_priority

#   def perform(download)
#     # sequentially download documents from all services
#     error, vbms_documents = DownloadVBMSManifestJob.perform_now(download)
#     if error
#       download.update_attributes!(status: error)
#       return
#     end

#     error, vva_documents = DownloadVVAManifestJob.perform_now(download)
#     if error
#       download.update_attributes!(status: error)
#       return
#     end

#     external_documents = vbms_documents + vva_documents

#     # update status of download
#     if external_documents.empty?
#       download.update_attributes!(status: :no_documents)
#     else
#       download.update_attributes!(status: :pending_confirmation)
#     end
#     external_documents

#     # efolder #675: Catch all errors and change the status so that the database row reflects
#     # that an erorr occurred and the efolder UI does not display a spinner forever.
#   rescue StandardError => e
#     download.update_attributes!(status: :manifest_fetch_error) if download.fetching_manifest?
#     raise e
#   end
# end
