# frozen_string_literal: true

require "tempfile"
require "open3"

class PdfService
  def self.write(filename, contents, pdf_attributes)
    # write attributes file to tmpfile
    pdf_attributes_file = write_attributes_file(pdf_attributes)

    # run pdftk, read pdf from stdin, update_info from above file, write to new
    escaped_filename = filename.gsub("'", "\\'")
    command = "pdftk - update_info '#{pdf_attributes_file.path}' output '#{escaped_filename}'"

    _stdout, stderr, _process = Open3.capture3(command, stdin_data: contents, binmode: true)

    # pdftk will crash on corrupt PDFs with the "Error: Unable to find file";
    # if this happens, write the file without attributes
    unless stderr.empty?
      # contents might come back as nil
      Rails.logger.warn("cannot write pdf of size #{contents.try(:size).to_i} via #{command}: #{stderr}")
      File.open(filename, "wb") do |f|
        f.write(contents)
      end
    end

    filename
  end

  def self.write_attributes_file(pdf_attributes)
    Tempfile.open("pdf-attributes") do |file|
      pdf_attributes.each do |key, value|
        file.puts "InfoBegin"
        file.puts "InfoKey: #{key}"
        file.puts "InfoValue: #{value}"
      end

      # open returns the value of the block
      file
    end
  end
end
