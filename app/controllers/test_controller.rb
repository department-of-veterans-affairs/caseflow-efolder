class TestController < ApplicationController
  def index
  end

  def touch_file
    TouchFileJob.perform_later(Rails.root.join("tmp/downloads_all/touched-file.txt").to_s)
    flash[:success] = 'file touch queued'
    render 'index'
  end
end
