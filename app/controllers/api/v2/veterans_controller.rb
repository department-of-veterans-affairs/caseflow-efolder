class Api::V2::VeteransController < Api::V2::ApplicationController
  def index
    file_number = verify_veteran_file_number
    return if performed?

    cache_key = "veteran-doc-count-#{file_number}"
    veteran = Veteran.new(file_number: file_number)
    doc_count = Rails.cache.fetch(cache_key, expires_in: 2.hours) do
      doc_counter = DocumentCounter.new(veteran: veteran)
      doc_counter.count
    end
    render json: { documents: doc_count }
  rescue ActiveRecord::RecordNotFound
    return record_not_found
  end
end
