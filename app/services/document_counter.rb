class DocumentCounter
  include ActiveModel::Model

  attr_accessor :veteran_file_number

  def count
    document_ids = []
    file_numbers.each do |file_number|
      [VBMSService, VVAService].each do |service|
        documents = service.v2_fetch_documents_for(file_number)
        document_ids << DocumentFilter.new(documents: documents).filter.map(&:document_id)
      end
    end
    document_ids.flatten.uniq.count
  end

  private

  def file_numbers
    vet_finder = VeteranFinder.new
    vet_finder.find(veteran_file_number).map { |vn| vn[:file] }.compact.uniq
  end
end
