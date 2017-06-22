class Fakes::DocumentService
  cattr_accessor :errors, :max_time

  def self.fetch_documents_for(_download)
    []
  end

  def self.fetch_document_file(_document)
    sleep(rand(max_time))
    fail VBMS::ClientError if errors && rand(5) == 3
    fail VVA::ClientError if errors && rand(5) == 2
    "this is some document, woah!"
  end
end