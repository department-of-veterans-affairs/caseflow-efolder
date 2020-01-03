module Caseflow
  class Fakes::S3Service
    cattr_accessor :files, default: {}

    def self.exists?(_key)
      true
    end

    def self.store_file(filename, content, type = :content)
      content = IO.read(content) if type == :filepath
      self.files[filename] = content
    end

    def self.fetch_file(filename, dest_filepath)
      File.open(dest_filepath, "wb") do |f|
        f.write(files[filename])
      end
    end

    def self.fetch_content(filename)
      Rails.logger.debug("Fakes::S3.fetch_content #{filename} present? #{self.files[filename].present?}")
      r = self.files[filename]
      Rails.logger.debug("Fakes::S3.fetch_content #{filename} got r")
      r
    end

    def self.stream_content(key)
      file = File.open(key, "r")
      Enumerator.new do |y|
        file.each_line do |segment|
          y << segment
        end
      end
    end
  end
end

S3Service = (Rails.application.config.s3_enabled ? Caseflow::S3Service : Caseflow::Fakes::S3Service)
