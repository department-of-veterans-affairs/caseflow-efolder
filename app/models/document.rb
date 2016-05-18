class Document < ActiveRecord::Base
  enum download_status: { pending: 0, success: 1, failed: 2 }

  def download_status_icon
    {
      "success" => :success,
      "failed" => :failed
    }[download_status]
  end
end
