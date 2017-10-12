class DownloadManifestJob < ActiveJob::Base
  queue_as :default

  # these must be implemented by child classes
  def service(download)
    nil
  end

  def service_name
    nil
  end

  def client_error
    Error
  end

  def manifest_fetched_at_name
    "manifest_#{service_name}_fetched_at"
  end


  def perform(download)
    external_documents = download_from_service(download)
    create_documents(download, external_documents)
  end


  private

  def create_documents(download, external_documents)
    # only indicate no_documents status if we've successfully completed fetching from services
    if external_documents.empty?
      download.update_attributes!(status: :no_documents)
      return
    end

    download_documents = DownloadDocuments.new(
      download: download,
      external_documents: external_documents
    )
    download_documents.create_documents
    download.update_attributes!(status: :pending_confirmation)
    download_documents
  end

  def download_from_service(download)
    s = service(download)
    return if not s
    external_documents = s.fetch_documents_for(download)
    download.update_attributes!({manifest_fetched_at_name => Time.zone.now})
    external_documents || []
  end

  def max_attempts
    1
  end

end
