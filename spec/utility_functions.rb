# frozen_string_literal: true

# Checks for a valid PDF as based on this stack overflow response
# https://stackoverflow.com/questions/28156467/fastest-way-to-check-that-a-pdf-
# is-corrupted-or-just-missing-eof-in-ruby
def valid_pdf?(data)
  pattern = /^startxref\n\d+\n%%EOF\n\z/m
  data.scrub =~ pattern
end
