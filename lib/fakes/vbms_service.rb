module Fakes::VbmsService
  class GetDocumentContent
    attr_reader :document_id

    def initialize(document_id)
      @document_id = document_id
    end

    def call
      # Simulate a response from VBMS
      FakeDocumentContent.generate_content(document_id)
    end
  end

  class FakeDocumentContent
    def self.generate_content(document_id)
      # Generate fake document content based on document_id
      "Fake content for document #{document_id}"
    end
  end
end
