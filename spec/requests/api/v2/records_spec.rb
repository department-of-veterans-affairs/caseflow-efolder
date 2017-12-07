describe "Records API v2", type: :request do
  context "Record by document ID" do
    let!(:current_user) do
      User.authenticate!(roles: ["Reader"])
    end

    let(:manifest) { Manifest.create(file_number: "1234") }
    let(:source) { ManifestSource.create(source: %w(VBMS VVA).sample, manifest: manifest) }

    let(:record) do
      Record.create(
        external_document_id: "{3333-3333}",
        manifest_source: source,
        received_at: Time.utc(2015, 9, 6, 1, 0, 0),
        type_id: "825",
        mime_type: "application/pdf"
      )
    end

    context "returns 401 if user does not have Reader role" do
      let!(:current_user) do
        User.authenticate!(roles: [""])
      end

      it do
        get "/api/v2/records/8888"
        expect(response.code).to eq("401")
      end
    end

    it "returns 404 if document ID is not found" do
      get "/api/v2/records/8888"
      expect(response.code).to eq("404")
    end

    context "when user owns corresponding download record" do
      let!(:user_manifest) { UserManifest.create(user: current_user, manifest: manifest) }

      it "returns a document" do
        allow(S3Service).to receive(:fetch_content).and_return("hello there")
        get "/api/v2/records/#{record.id}"
        expect(response.code).to eq("200")
        expect(response.body).to eq("hello there")
        expect(response.headers["Cache-Control"]).to match(/2592000/)
      end

      it "returns 502 if there is a VBMS/VVA error" do
        allow(Fakes::DocumentService).to receive(:fetch_document_file)
          .and_raise([VBMS::ClientError, VVA::ClientError].sample)

        get "/api/v2/records/#{record.id}"

        expect(response.code).to eq("502")

        json = JSON.parse(response.body)
        expect(json["errors"].length).to eq(1)
        expect(json["errors"].first["title"]).to eq("Document download failed")
        expect(json["errors"].first["detail"]).to eq("An upstream dependency failed to fetch document contents.")
      end

      it "returns 500 if there is a StaleObjectError error" do
        allow_any_instance_of(RecordFetcher).to receive(:process).and_raise(ActiveRecord::StaleObjectError.new(nil, nil))
        expect(Raven).to receive(:capture_exception)
        expect(Raven).to receive(:last_event_id).and_return("a1b2c3")

        get "/api/v2/records/#{record.id}"

        expect(response.code).to eq("500")

        json = JSON.parse(response.body)
        expect(json["errors"].length).to eq(1)
        expect(json["errors"].first["title"]).to eq("Unknown error occured")
        expect(json["errors"].first["detail"]).to eq("Attempted to  a stale object: NilClass (Sentry event id: a1b2c3)")
      end

      it "returns 500 on any other error" do
        allow_any_instance_of(RecordFetcher).to receive(:process).and_raise("Much random error")
        expect(Raven).to receive(:capture_exception)
        expect(Raven).to receive(:last_event_id).and_return("a1b2c3")

        get "/api/v2/records/#{record.id}"

        expect(response.code).to eq("500")

        json = JSON.parse(response.body)
        expect(json["errors"].length).to eq(1)
        expect(json["errors"].first["title"]).to eq("Unknown error occured")
        expect(json["errors"].first["detail"]).to match("Much random error (Sentry event id: a1b2c3)")
      end
    end

    context "when user doesn't own corresponding download record" do
      it "returns 403" do
        get "/api/v2/records/#{record.id}"
        expect(response.code).to eq("403")
        body = JSON.parse(response.body)
        expect(body["status"]).to match(/sensitive/)
      end
    end
  end
end
