class Document < ActiveRecord::Base
  enum download_status: { pending: 0, success: 1, failed: 2 }

  def filename
    "#{vbms_filename.gsub(/\.\w+$/, '')}.#{preferred_extension}"
  end

  def download_status_icon
    {
      "success" => :success,
      "failed" => :failed
    }[download_status]
  end

  private

  def preferred_extension
    mime = MIME::Types[mime_type].first
    mime ? mime.preferred_extension : ""
  end
end
