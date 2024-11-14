# frozen_string_literal: true

# monkeypatch some error classes to conform with BGS/VBMS error classes.

class StandardError
  def ignorable?
    false
  end
end
