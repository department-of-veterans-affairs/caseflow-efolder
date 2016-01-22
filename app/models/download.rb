class Download < ActiveRecord::Base
	enum status: {fetching_manifest: 0}

	STATUS_MESSAGES = {
		"fetching_manifest" => "Fetching eFolder document manifest"
	}
end
