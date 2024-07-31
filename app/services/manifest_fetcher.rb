class ManifestFetcher
  include ActiveModel::Model

  attr_accessor :manifest_source

  EXCEPTIONS = [VBMS::ClientError, VVA::ClientError, ClaimEvidenceApi::Error::ClaimEvidenceApiError].freeze

  def process
    DocumentCreator.new(manifest_source: manifest_source, external_documents: documents).create
    manifest_source.update!(status: :success, fetched_at: Time.zone.now)
    documents
  rescue *EXCEPTIONS => e
    manifest_source.update!(status: :failed)
    ExceptionLogger.capture(e)
    raise e
  ensure
    return documents
  end

  def documents
    @documents ||= fetch_documents
  end

  def fetch_documents
    # fetch documents for all the "file numbers" known for this veteran
    # it's possible that BGS reports a FN that VBMS does not know about.
    # so do not report the error if at least one FN works.
    file_numbers_found = {}
    errors = []
    documents = file_numbers.map do |file_number|
      begin
        docs = documents_from_service_for(file_number)
        file_numbers_found[file_number] = true
        docs
      rescue VBMS::FilenumberDoesNotExist => error
        errors << error
        []
      end
    end.flatten.uniq
    if file_numbers_found.empty?
      fail errors.first # don't care if there is more than one.
    end
    documents
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
    # always use system user so authz is not a question.
    # the authz checks are performed before this class is invoked.
    BGSService.init_client(username: User.system_user.css_id, station_id: User.system_user.station_id)
  end

  private

  # If manifest not current fetch all documents from VBMS
  # If manifest current, fetch delta documents from VBMS 
  # without feature flag, always fetch all documents from VBMS
  def fetch_documents_or_delta_documents_for(file_number)
    ft_delta_documents = FeatureToggle.enabled?(:cache_delta_documents, user: current_user)

    if ft_delta_documents
      docs = manifest_source.current? ? manifest_source.service.fetch_delta_documents_for(file_number, manifest_source.fetched_at) : manifest_source.service.v2_fetch_documents_for(file_number)
    else
      docs = manifest_source.service.v2_fetch_documents_for(file_number)
    end
    
    log_info(file_number, docs, ft_delta_documents, manifest_source.manifest.zipfile_size)

    docs
  end
  

  def documents_from_service_for(file_number)
    documents = MetricsService.record("ManifestFetcher documents or delta documents for file_number: #{file_number}",
                                               service: manifest_source.name.downcase.to_sym,
                                               name: "fetch_documents_or_delta_from_service") do
      fetch_documents_or_delta_documents_for(file_number)
    end
  end


  def current_user
    RequestStore[:current_user]
  end

  def log_info(file_number, docs, ft_delta_documents, zipfile_size)
    Rails.logger.info log_message(file_number, docs, ft_delta_documents, zipfile_size)
  end

  def log_message(file_number, docs, ft_delta_documents, zipfile_size)
    "ManifestFetcher - " \
    "Feature Flag Delta Docs: #{ft_delta_documents} - " \
    "User Inspect: (#{current_user.inspect})" \
    "File Number: (#{file_number}) - " \
    "Documents Fetched Count: #{docs.count} - " \
    "Documents Fetched IDs: #{docs.map(&:id)}" \
    "Manifest Zipfile Size: #{zipfile_size} - "
  end
end
