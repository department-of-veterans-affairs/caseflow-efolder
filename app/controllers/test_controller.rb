class TestController < ApplicationController
  def index
  end

  def download
    send_file touched_file, filename: "touched-file-download.txt"
  end

  def touch_file
    TouchFileJob.perform_later(touched_file)
    flash[:success] = 'file touch queued'
    render 'index'
  end

  private

  def touched_file
    Rails.root.join("tmp/downloads_all/touched-file.txt").to_s
  end
end
