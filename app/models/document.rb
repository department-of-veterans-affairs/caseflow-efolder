class Document < ActiveRecord::Base
  enum download_status: { pending: 0, success: 1, failed: 2 }
end
