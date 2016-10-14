class Document < ActiveRecord::Base
  include DocumentTypes

  enum download_status: { pending: 0, success: 1, failed: 2 }

  after_initialize { |document| document.vbms_filename ||= "" }

  def filename
    Zaru.sanitize! "#{type_name}-#{filename_date}-#{filename_doc_id}.#{preferred_extension}"
  end

  def filename_date
    received_at ? received_at.to_formatted_s(:filename) : "00000000"
  end

  def filename_doc_id
    (document_id || "").gsub(/[}{]/, "")
  end

  def s3_filename
    "#{download_id}-#{id}-#{vbms_filename}"
  end

  def download_status_icon
    {
      "success" => :success,
      "failed" => :failed
    }[download_status]
  end

  def type_name
    TYPES[doc_type.to_i] || vbms_filename
  end

  private

  def preferred_extension
    mime = MIME::Types[mime_type].first
    mime ? mime.preferred_extension : ""
  end
end
