require "zip"

class ZipfileCreator
  include ActiveModel::Model

  attr_accessor :manifest

  def process
    records = manifest.records
    return if records.blank?

    t = Tempfile.new
    write_to_tempfile(t, records)

    S3Service.store_file(manifest.s3_filename, t.path, :filepath)
    zipfile_size = File.size(t.path)
    t.close
    t.unlink
    zipfile_size
  end

  private

  def write_to_tempfile(t, records)
    index = 0
    Zip::OutputStream.open(t.path) do |z|
      records.each do |record|
        content = record.fetch!
        unless content
          record.update(status: :failed)
          next
        end
        z.put_next_entry(unique_filename(record, index))
        z.print(content)
        record.update(status: :success)
        index += 1
      end
    end
  end

  def unique_filename(record, index)
    "#{format('%04d', index + 1)}0-#{record.filename}"
  end
end
