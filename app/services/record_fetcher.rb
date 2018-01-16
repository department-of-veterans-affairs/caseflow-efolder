class RecordFetcher
  include ActiveModel::Model

  attr_accessor :record

  EXCEPTIONS = [VBMS::ClientError, VVA::ClientError].freeze

  def process
    wait_while_pending

    if content_from_s3
      record.update(status: :success)
      return content_from_s3
    end

    record.update(status: :pending)
    content = content_from_vbms
    record.update(status: :success)

    content
  rescue *EXCEPTIONS
    record.update(status: :failed)
    nil
  # Catch StandardError in case there is an error to avoid records being stuck in pending state
  rescue StandardError => e
    record.update(status: :failed)
    raise e
  end

  private

  def wait_while_pending
    return if Rails.env.test?
    20.times do
      break unless record.pending?
      sleep 1
    end
  end

  def content_from_vbms
    content = record.service.v2_fetch_document_file(record)
    content = ImageConverterService.new(image: content, record: record).process
    S3Service.store_file(record.s3_filename, content)
  end

  def content_from_s3
    @content_from_s3 ||= MetricsService.record("S3: fetch content for: #{record.s3_filename}",
                                               service: :s3,
                                               name: "content_from_s3") do
      S3Service.fetch_content(record.s3_filename)
    end
  end
end
