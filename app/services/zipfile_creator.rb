require 'zip'

class ZipfileCreator
  include ActiveModel::Model

  attr_accessor :manifest

  def process
    records = manifest.records
    return if records.empty?

    t = Tempfile.new
    index = 0

    Zip::OutputStream.open(t.path) do |z|
      records.each do |record|
        content = record.fetch!
        next unless content
        z.put_next_entry(unique_filename(record, index))
        z.print(content) and index += 1
      end
    end
    S3Service.store_file(manifest.s3_filename, t.path, :filepath)
    manifest.update(zipfile_size: File.size(t.path))
    t.close
    t.unlink
  end

  private

  def unique_filename(record, index)
    "#{format('%04d', index + 1)}0-#{record.filename}"
  end
end
