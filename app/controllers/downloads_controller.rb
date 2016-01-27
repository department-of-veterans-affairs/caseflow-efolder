class DownloadsController < ApplicationController
  def new
    @download = Download.new
  end

  def create
    download = Download.create!(file_number: params[:file_number])

    DownloadListingJob.perform_later(download)

    redirect_to download_url(download)
  end

  def show
    @download = Download.find(params[:id])
  end

  def download
    download_id = params[:id]
    download = Download.find(download_id)

    # TODO: assert completed state

    # stream zip response back

    # TODO: this build the entire zip in memory which is huge, not practical; need to stream directly to response
    zip = EFolderExpress.zip_documents(download)

    zip_name = download.file_number.gsub('"', '\"')

    send_data(zip.string, :filename => "#{zip_name}.zip", :type => Mime::Type.lookup_by_extension('zip').to_s)
  end

  class ZipGenerator
    def initialize(documents)
      @documents = documents
    end

    def each(&block)
      block.call("hi")
    end
  end
end
