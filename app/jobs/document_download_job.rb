class DocumentDownloadJob < ActiveJob::Base
  queue_as :default

  def perform(document)
    EFolderExpress.download_document(document)
  end
end