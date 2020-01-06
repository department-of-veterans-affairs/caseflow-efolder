class TestController < ApplicationController
  def index
  end

  def download
    return send_file touched_file, filename: "touched-file-download.txt"

    headers["Content-Type"] = "text/plain"
    headers["Content-disposition"] = "attachment; filename=\"touched-file-download.txt\""
    headers["Content-Length"] = File.size(touched_file)
    headers["X-Accel-Buffering"] = "no"
    headers["Cache-Control"] ||= "no-cache"
    self.response_body = File.read(touched_file)
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
