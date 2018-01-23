describe V2::PackageFilesJob do
  context "#perform" do
    let(:user) { User.create(css_id: "Foo", station_id: "112") }
    let(:manifest) { Manifest.find_or_create_by_user(user: user, file_number: "1234") }
    let(:source) { ManifestSource.create(source: %w[VBMS VVA].sample, manifest: manifest) }

    let!(:records) do
      [
        source.records.create(
          received_at: Time.utc(2015, 1, 3, 17, 0, 0),
          type_id: "497",
          version_id: "{ABC123-DEF123-GHI456A}",
          series_id: "{ABC321-DEF123-GHI456A}",
          mime_type: "application/pdf"
        ),
        source.records.create(received_at: Time.utc(2015, 1, 3, 17, 0, 0),
                              type_id: "497",
                              version_id: "{CBA123-DEF123-GHI456A}",
                              series_id: "{CBA321-DEF123-GHI456A}",
                              mime_type: "application/pdf")
      ]
    end

    subject { V2::PackageFilesJob.perform_now(manifest) }

    context "when VBMS/VVA requests are successful" do
      it "sets status to finished" do
        allow(S3Service).to receive(:store_file).and_return(nil)
        subject
        # 2 times for uploading documents and 1 time for uploading a zip file
        expect(S3Service).to have_received(:store_file).exactly(3).times
        expect(manifest.fetched_files_status).to eq "finished"
      end
    end

    context "when VBMS/VVA requests are not successful" do
      it "sets status to finished" do
        allow(S3Service).to receive(:store_file).and_return(nil)
        allow(Fakes::DocumentService).to receive(:v2_fetch_document_file).and_raise([VBMS::ClientError, VVA::ClientError].sample)
        subject
        # 1 time for uploading a zip file
        expect(S3Service).to have_received(:store_file).once
        expect(manifest.fetched_files_status).to eq "finished"
      end
    end

    context "when any error" do
      it "sets status to failed" do
        allow_any_instance_of(Record).to receive(:fetch!).and_raise("Application error")
        expect { subject }.to raise_error("Application error")
        expect(manifest.fetched_files_status).to eq "failed"
      end
    end
  end
end
