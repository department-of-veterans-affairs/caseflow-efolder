# for tests only

class TouchFileJob < ApplicationJob
  queue_as :high_priority

  def perform(file_path)
    open(file_path, 'w') { |f| f.puts "Hello, world." }
  end
end
