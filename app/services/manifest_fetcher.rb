class ManifestFetcher
  include ActiveModel::Model

  attr_accessor :manifest_source

  def process
    fetch_and_create_documents
    manifest_source.update!(status: :success, fetched_at: Time.zone.now)
  rescue StandardError => e
    handle_error(e)
    raise e
  ensure
    documents
  end

  private

  def fetch_and_create_documents
    DocumentCreator.new(manifest_source: manifest_source, external_documents: documents).create
  end

  def handle_error(error)
    manifest_source.update!(status: :failed)
    ExceptionLogger.capture(error)
  end

  def documents
    @documents ||= fetch_documents
  end

  def fetch_documents
    file_numbers.flat_map do |file_number|
      begin
        documents_from_service_for(file_number)
      rescue VBMS::FilenumberDoesNotExist => error
        log_error(error)
        []
      end
    end.uniq
  end

  def documents_from_service_for(file_number)
    MetricsService.record("ManifestFetcher documents or delta documents for file_number: #{file_number}",
                          service: manifest_source.name.downcase.to_sym,
                          name: "fetch_documents_or_delta_from_service") do
      fetch_documents_or_delta_documents_for(file_number)
    end
  end

  def fetch_documents_or_delta_documents_for(file_number)
    ft_delta_documents = FeatureToggle.enabled?(:cache_delta_documents, user: current_user)
    manifest_source.service.fetch_or_delta_documents(file_number, ft_delta_documents, manifest_source)
  end

  def current_user
    RequestStore[:current_user]
  end

  def file_numbers
    @file_numbers ||= [
      manifest_source.file_number,
      vet_finder.find_uniq_file_numbers(manifest_source.file_number)
    ].flatten.uniq
  end

  def vet_finder
    @vet_finder ||= VeteranFinder.new(bgs: bgs)
  end

  def bgs
    @bgs ||= BGSService.new(client: bgs_client)
  end

  def bgs_client
    BGSService.init_client(username: User.system_user.css_id, station_id: User.system_user.station_id)
  end

  def log_error(error)
    Rails.logger.error("ManifestFetcher: #{error.message}")
  end
end
