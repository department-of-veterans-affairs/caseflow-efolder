class Document < ActiveRecord::Base
  belongs_to :download

  enum download_status: {pending: 0, success: 1, failed: 2}
end
