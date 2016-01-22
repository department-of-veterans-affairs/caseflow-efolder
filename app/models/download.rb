class Download < ActiveRecord::Base
	enum status: {fetching_manifest: 0, no_documents: 1, pending_documents: 2}

	has_many :documents
end
