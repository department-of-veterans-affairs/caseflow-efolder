class Download < ActiveRecord::Base
  enum status: {fetching_manifest: 0, no_documents: 1, pending_documents: 2, complete: 3}

  has_many :documents

  def complete_documents
    documents.select { |d| !d.pending? }
  end

  def pending_documents
    documents.select { |d| d.pending? }
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
end
