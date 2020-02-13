class DocumentCounter
  include ActiveModel::Model

  attr_accessor :veteran_file_number

  def count
    total = 0
    [VBMSService, VVAService].each do |service|
      documents = service.v2_fetch_documents_for(veteran_file_number)
      total += DocumentFilter.new(documents: documents).filter.uniq(&:document_id).count
    end
    total
  end
end
