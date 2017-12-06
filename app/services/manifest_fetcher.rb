class ManifestFetcher
  include ActiveModel::Model

  attr_accessor :manifest_source

  EXCEPTIONS = [VBMS::ClientError, VVA::ClientError].freeze

  def process
    manifest_source.update(status: :pending)
    documents = manifest_source.service.fetch_documents_for(manifest_source.manifest)
    manifest_source.update(status: :success, fetched_at: Time.zone.now)
    documents
  rescue *EXCEPTIONS => e
    manifest_source.update(status: :failed)
    log_error(e)
    []
  end

  def log_error(e)
    Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
    Raven.capture_exception(e)
  end
end
