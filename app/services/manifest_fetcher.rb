class ManifestFetcher
  include ActiveModel::Model

  attr_accessor :manifest_source

  EXCEPTIONS = [VBMS::ClientError, VVA::ClientError].freeze

  def process
    DocumentCreator.new(manifest_source: manifest_source, external_documents: documents).create
    manifest_source.update!(status: :success, fetched_at: Time.zone.now)
    documents
  rescue *EXCEPTIONS => e
    manifest_source.update!(status: :failed)
    ExceptionLogger.capture(e)
    []
  end

  def documents
    @documents ||= fetch_documents
  end

  def fetch_documents
    # fetch documents for all the "file numbers" known for this veteran
    file_numbers.map do |file_number|
      manifest_source.service.v2_fetch_documents_for(file_number)
    end.flatten
  end

  def file_numbers
    vet_finder = VeteranFinder.new
    [manifest_source.file_number, vet_finder.find_uniq_file_numbers(manifest_source.file_number)].flatten.uniq
  end
end
