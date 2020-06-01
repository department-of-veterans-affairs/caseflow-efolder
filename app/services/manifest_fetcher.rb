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
    # it's possible that BGS reports a FN that VBMS does not know about.
    # so do not report the error if at least one FN works.
    file_numbers_found = {}
    errors = []
    documents = file_numbers.map do |file_number|
      break if file_numbers_found.keys.any? # abort loop if first succeeded
      begin
        docs = manifest_source.service.v2_fetch_documents_for(file_number)
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
end
