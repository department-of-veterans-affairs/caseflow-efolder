describe "Records API v2", type: :request do
  include ActiveJob::TestHelper

  context "Record by document ID" do
    let!(:current_user) do
      User.authenticate!(roles: ["Reader"])
    end

    let(:manifest) { Manifest.create(file_number: "1234") }
    let(:source) { ManifestSource.create(name: %w[VBMS VVA].sample, manifest: manifest) }
    let(:manifest2) { Manifest.create(file_number: "5678") }
    let(:source2) { ManifestSource.create(name: %w[VBMS VVA].sample, manifest: manifest2) }

    let(:version_id) { "3333-3333" }
    let(:full_version_id) { "{#{version_id}}" }

    let!(:record) do
      Record.create!(
        created_at: Time.zone.now - 5.days,
        version_id: full_version_id,
        manifest_source: source,
        series_id: "{4444-4444}",
        received_at: Time.utc(2015, 9, 6, 1, 0, 0),
        type_id: "825",
        mime_type: "old/record"
      )
    end

    let!(:record2) do
      Record.create!(
        created_at: Time.zone.now,
        version_id: full_version_id,
        manifest_source: source2,
        series_id: "{4444-4444}",
        received_at: Time.utc(2015, 9, 6, 1, 0, 0),
        type_id: "825",
        mime_type: "application/pdf"
      )
    end

    context "when user does not have Reader role" do
      let!(:current_user) do
        User.authenticate!(roles: [""])
      end

      it "returns 401 " do
        get "/api/v2/records/8888"
        expect(response.code).to eq("401")
      end
    end

    it "returns 404 if document ID is not found" do
      get "/api/v2/records/8888"
      expect(response.code).to eq("404")
    end

    context "when user has access to the corresponding manifest record" do
      let!(:files_download) { FilesDownload.create(user: current_user, manifest: manifest2) }

      it "returns the latest document" do
        allow(S3Service).to receive(:fetch_content).and_return("hello there")
        get "/api/v2/records/#{version_id}"
        expect(response.code).to eq("200")
        expect(response.body).to eq("hello there")
        expect(response.media_type).to eq(record2.mime_type)
        expect(response.headers["Cache-Control"]).to match(/2592000/)
      end

      it "returns 502 if there is a VBMS/VVA error" do
        allow_any_instance_of(RecordFetcher).to receive(:process).and_return(nil)
        record2.update(status: :failed)

        get "/api/v2/records/#{version_id}"

        expect(response.code).to eq("502")

        json = JSON.parse(response.body)
        expect(json["errors"].length).to eq(1)
        expect(json["errors"].first["title"]).to eq("Document download failed")
        expect(json["errors"].first["detail"]).to eq("An upstream dependency failed to fetch document contents.")
      end

      it "returns 500 if there is a StaleObjectError error" do
        FeatureToggle.disable!(:vbms_to_reader_on_s3_miss, users: [current_user])
        allow_any_instance_of(RecordFetcher).to receive(:process).and_raise(ActiveRecord::StaleObjectError.new(nil, nil))
        expect(Raven).to receive(:capture_exception)
        expect(Raven).to receive(:last_event_id).and_return("a1b2c3")

        get "/api/v2/records/#{version_id}"

        expect(response.code).to eq("500")

        json = JSON.parse(response.body)
        expect(json["errors"].length).to eq(1)
        expect(json["errors"].first["title"]).to eq("Unknown error occured")
        expect(json["errors"].first["detail"]).to eq("Stale object error. (Sentry event id: a1b2c3)")
      end

      it "returns 500 on any other error" do
        FeatureToggle.disable!(:vbms_to_reader_on_s3_miss, users: [current_user])
        allow_any_instance_of(RecordFetcher).to receive(:process).and_raise("Much random error")
        expect(Raven).to receive(:capture_exception)
        expect(Raven).to receive(:last_event_id).and_return("a1b2c3")

        get "/api/v2/records/#{version_id}"

        expect(response.code).to eq("500")

        json = JSON.parse(response.body)
        expect(json["errors"].length).to eq(1)
        expect(json["errors"].first["title"]).to eq("Unknown error occured")
        expect(json["errors"].first["detail"]).to match("Much random error (Sentry event id: a1b2c3)")
      end
    end

    context "when user doesn't own corresponding download record" do
      it "returns 403" do
        get "/api/v2/records/#{version_id}"
        expect(response.code).to eq("403")
        body = JSON.parse(response.body)
        expect(body["status"]).to match(/sensitive/)
      end
    end

    context "document_source_to_headers" do
      let!(:files_download) { FilesDownload.create(user: current_user, manifest: manifest2) }

      context "when document is not in S3" do
        it "headers include X-Document-Source is VBMS" do
          FeatureToggle.disable!(:vbms_to_reader_on_s3_miss, users: [current_user])
          allow(S3Service).to receive(:exists?).and_return(false)
          expect(S3Service).to receive(:fetch_content).and_return nil
          allow(Fakes::DocumentService).to receive(:v2_fetch_document_file)
          expect(S3Service).to receive(:store_file)
          get "/api/v2/records/#{version_id}"
          expect(response.code).to eq("200")
          expect(response.headers["X-Document-Source"]).to eq("VBMS")
        end
      end

      context "when document is in S3" do
        it "headers include X-Document-Source is S3" do
          FeatureToggle.disable!(:vbms_to_reader_on_s3_miss, users: [current_user])
          allow(S3Service).to receive(:fetch_content).and_return("much document")
          expect(VBMSService).not_to receive(:v2_fetch_document_file)
          expect(S3Service).not_to receive(:store_file)
          expect(S3Service).to receive(:fetch_content)
          get "/api/v2/records/#{version_id}"
          expect(response.code).to eq("200")
          expect(response.headers["X-Document-Source"]).to eq("S3")
        end
      end

      context "when reader api call get S3 cache hit" do
        before { FeatureToggle.enable!(:vbms_to_reader_on_s3_miss) }
        after { FeatureToggle.disable!(:vbms_to_reader_on_s3_miss) }

        it "headers include X-Document-Source is S3" do
          allow(S3Service).to receive(:fetch_content).and_return("much document")
          expect(S3Service).to receive(:fetch_content)
          get "/api/v2/records/#{version_id}"
          expect(response.code).to eq("200")
          expect(response.headers["X-Document-Source"]).to eq("S3")
        end
      end

      context "when reader api call gets S3 cache miss" do
        before { FeatureToggle.enable!(:vbms_to_reader_on_s3_miss) }
        after { FeatureToggle.disable!(:vbms_to_reader_on_s3_miss) }

        it "headers include X-Document-Source is VBMS" do
          allow(S3Service).to receive(:exists?).and_return(false)
          expect(S3Service).to receive(:fetch_content).and_return nil
          allow(Fakes::DocumentService).to receive(:v2_fetch_document_file)
          get "/api/v2/records/#{version_id}"
          expect(response.code).to eq("200")
        end
      end
    end

  end
end
