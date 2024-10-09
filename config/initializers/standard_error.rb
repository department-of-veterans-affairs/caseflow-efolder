# frozen_string_literal: true

# monkeypatch some error classes to conform with BGS/VBMS error classes.
Rails.application.config.before_initialize do
  class StandardError
    def ignorable?
      false
    end
  end
end
