class DocumentCounter
  include ActiveModel::Model

  attr_accessor :veteran_file_number

  def count
    total = 0
    [VBMSService, VVAService].each do |service|
      source = OpenStruct.new(file_number: veteran_file_number)
      documents = service.v2_fetch_documents_for(source)
      total += DocumentFilter.new(documents: documents).filter.count
    end
    total
  end
end
