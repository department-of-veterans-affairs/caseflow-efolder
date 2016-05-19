class Download < ActiveRecord::Base
  enum status: { fetching_manifest: 0, no_documents: 1, pending_confirmation: 2, pending_documents: 3, complete: 4 }

  has_many :documents

  def demo?
    file_number =~ /DEMO/
  end

  def veteran_name
    @veteran_name ||= demo? ? "TEST" : Download.bgs_service.fetch_veteran_name(file_number)
  end

  def case_exists?
    Download.bgs_service.fetch_veteran_name(file_number)
    true
  rescue
    false
  end

  def confirmed?
    pending_documents? || complete?
  end

  def complete_documents
    documents.select { |d| !d.pending? }
  end

  def progress_percentage
    if fetching_manifest?
      20
    elsif pending_documents?
      20 + ((complete_documents.count + 1.0) / (documents.count + 1.0) * 80).round
    else
      100
    end
  end

  class << self
    attr_writer :bgs_service

    def bgs_service
      @bgs_service ||= BGSService
    end
  end
end
