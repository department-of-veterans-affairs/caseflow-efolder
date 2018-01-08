describe V2::PackageFilesJob do
  context "#perform" do
    let(:user) { User.create(css_id: "Foo", station_id: "112") }
    let(:manifest) { Manifest.find_or_create_by_user(user: user, file_number: "1234") }
    let(:user_manifest) { manifest.user_manifests.last }
    let(:source) { ManifestSource.create(source: %w[VBMS VVA].sample, manifest: manifest) }

    let!(:records) do
      [
        source.records.create(external_document_id: "1234"),
        source.records.create(external_document_id: "5678")
      ]
    end

    subject { V2::PackageFilesJob.perform_now(user_manifest) }

    context "when VBMS/VVA requests are successful" do
      it "sets status to finished" do
        allow(S3Service).to receive(:store_file).and_return(nil)
        subject
        expect(S3Service).to have_received(:store_file).twice
        expect(user_manifest.status).to eq "finished"
      end
    end

    context "when VBMS/VVA requests are not successful" do
      it "sets status to finished" do
        allow(S3Service).to receive(:store_file).and_return(nil)
        allow(Fakes::DocumentService).to receive(:fetch_document_file).and_raise([VBMS::ClientError, VVA::ClientError].sample)
        subject
        expect(S3Service).to_not have_received(:store_file)
        expect(user_manifest.status).to eq "finished"
      end
    end

    context "when any error" do
      it "sets status to failed" do
        allow_any_instance_of(Record).to receive(:fetch!).and_raise("Application error")
        expect { subject }.to raise_error("Application error")
        expect(user_manifest.status).to eq "failed"
      end
    end
  end
end
