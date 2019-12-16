# https://github.com/rubyzip/rubyzip#configuration

require "zip"

Zip.setup do |c|
#  c.on_exists_proc = true
#  c.continue_on_exists_proc = true
  c.unicode_names = true
  c.default_compression = Zlib::BEST_COMPRESSION
  c.write_zip64_support = true
end
