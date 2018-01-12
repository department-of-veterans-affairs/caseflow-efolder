describe "Files Downloads API v2", type: :request do
  include ActiveJob::TestHelper

  context "Files Downloads by manifest ID" do
    let!(:current_user) do
      User.authenticate!(roles: ["Reader"])
    end

    let(:manifest) { Manifest.create(file_number: "1234") }
    let(:source) { ManifestSource.create(source: %w[VBMS VVA].sample, manifest: manifest) }

    let!(:records) do
      [Record.create(
        version_id: "{3333-3333}",
        series_id: "{4444-4444}",
        manifest_source: source,
        received_at: Time.utc(2015, 9, 6, 1, 0, 0),
        type_id: "825",
        mime_type: "application/pdf"
      ),
       Record.create(
         version_id: "{3333-3336}",
         series_id: "{4444-4447}",
         manifest_source: source,
         received_at: Time.utc(2012, 9, 6, 1, 0, 0),
         type_id: "825",
         mime_type: "application/pdf"
       )]
    end

    it "returns 404 if manifest ID is not found" do
      get "/api/v2/manifests/8888/files_downloads"
      expect(response.code).to eq("404")
    end

    context "when VBMS/VVA is up and running" do
      let!(:files_download) { FilesDownload.create(user: current_user, manifest: manifest) }
      before do
        allow(S3Service).to receive(:fetch_content).and_return(nil)
        allow(Fakes::DocumentService).to receive(:fetch_document_file).and_return("stuff")
      end

      it "returns status finished with all documents with successful statuses" do
        perform_enqueued_jobs do
          post "/api/v2/manifests/#{manifest.id}/files_downloads"
        end
        get "/api/v2/manifests/#{manifest.id}/files_downloads"
        expect(response.code).to eq("200")
        response_body = JSON.parse(response.body)["data"]["attributes"]
        expect(response_body["status"]).to eq "finished"
        expect(response_body["records"].collect { |r| r["status"] }).to eq %w[success success]
      end
    end

    context "when VBMS/VVA is down" do
      let!(:files_download) { FilesDownload.create(user: current_user, manifest: manifest) }
      before do
        allow(S3Service).to receive(:fetch_content).and_return(nil)
        allow(Fakes::DocumentService).to receive(:fetch_document_file).and_raise([VBMS::ClientError, VVA::ClientError].sample)
      end

      it "returns status finished with all documents with failed statuses" do
        perform_enqueued_jobs do
          post "/api/v2/manifests/#{manifest.id}/files_downloads"
        end
        get "/api/v2/manifests/#{manifest.id}/files_downloads"
        expect(response.code).to eq("200")
        response_body = JSON.parse(response.body)["data"]["attributes"]
        expect(response_body["status"]).to eq "finished"
        expect(response_body["records"].collect { |r| r["status"] }).to eq %w[failed failed]
      end
    end
  end
end
