class EFolderExpress
  @@io = DocIo.new({encryption_key: Rails.application.secrets.secret_key_base,
                    download_dir_base: Rails.application.config.download_filepath})
  @@vbms = VBMSService

  def self.check_demo(download)
    if download.file_number =~ /DEMO/
      self.vbms = DemoVBMSService
    end
  end

  def self.vbms=(vbms)
    @@vbms = vbms
  end

  class DemoVBMSService

    def self.fetch_document_listing(case_id)
      (1...5).collect { |index| {
          document_id: index,
          filename: "file #{index}",
          doc_type: '',
          source: '',
          mime_type: 'application/pdf',
          received_at: Time.now
      } }
    end

    def self.fetch_document_contents(document_id)
      "test-contents for #{document_id}".bytes
    end

  end

  def self.read(document)
    @@io.retrieve_decrypted(document.filepath)
  end

  def self.download_listing(download)
    self.check_demo(download)
    vbms_documents = @@vbms.fetch_document_listing(download.file_number)

    # no docs, done
    download.update_attributes!(status: :no_documents) && return if vbms_documents.empty?

    # mark as pending
    download.update_attributes!(status: :pending_documents)

    # create document records in db
    documents = Document.create(vbms_documents.collect { |vbms_doc|
      {download_id: download.id, document_id: vbms_doc[:document_id], filename: vbms_doc[:filename],
       source: vbms_doc[:source], mime_type: vbms_doc[:mime_type], doc_type: vbms_doc[:doc_type]}
    })

    documents
  end

  def self.download_document(document)
    self.check_demo(document.download)

    begin
      contents_bytes = @@vbms.fetch_document_contents(document.id)

      filepath = @@io.save_encrypted(contents_bytes)
      document.update_attributes!(filepath: filepath, download_status: :success)

      pending_docs = document.download.pending_documents

      # none left
      if pending_docs.empty?
        document.download.update_attributes(status: :complete)
      end
    rescue VBMS::ClientError
      document.update_attributes!(download_status: :failed)
    end
  end

  def self.zip_documents(download, zip = StringIO.new)
    Zip::OutputStream.write_buffer(io=zip) do |zip|
      download.documents.each do |document|
        entry_name = document.filename
        contents = EFolderExpress.read(document).pack("U*")
        zip.put_next_entry entry_name
        zip.write contents
      end
    end
    zip
  end
end