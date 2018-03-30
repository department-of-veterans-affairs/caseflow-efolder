class DownloadManifestJob < ApplicationJob
  queue_as :high_priority

  # these must be implemented by child classes
  def get_service(_download)
    raise "get_service must be implemented by a child class of DownloadManifestJob"
  end

  def service_name
    raise "service_name must be implemented by a child class of DownloadManifestJob"
  end

  def client_error
    raise "client_error must be implemented by a child class of DownloadManifestJob"
  end

  def manifest_fetched_at_name
    "manifest_#{service_name}_fetched_at"
  end

  def connection_error_tag
    "#{service_name}_connection_error"
  end

  # obtain docs from a service and save to the document model
  # returns <error>, <array of fetched documents>
  def perform(download)
    # Short circuit if the current service is nil (i.e. not enabled)
    return nil, [] if !get_service(download)

    external_documents = download_from_service(download)
    create_documents(download, external_documents) if !external_documents.empty?
    download.update_attributes!(manifest_fetched_at_name => Time.zone.now)
    return nil, external_documents
  rescue client_error => e
    ExceptionLogger.capture(e)
    return connection_error_tag, nil
  end

  private

  def create_documents(download, external_documents)
    download_documents = DownloadDocuments.new(
      download: download,
      external_documents: external_documents
    )
    download_documents.create_documents
  end

  def download_from_service(download)
    service = get_service(download)
    external_documents = service.fetch_documents_for(download)
    external_documents || []
  end

  def max_attempts
    1
  end
end
