class Download < ActiveRecord::Base
	enum status: {fetching_manifest: 0, no_documents: 1}

	STATUS_MESSAGES = {
		"fetching_manifest" => "Fetching eFolder document manifest...",
		"no_documents" => "No documents found"
	}
end
