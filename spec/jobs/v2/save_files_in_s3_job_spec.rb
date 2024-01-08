describe V2::SaveFilesInS3Job do
  context "#perform" do
    let(:manifest) { Manifest.create(file_number: "1234") }
    let(:source) { ManifestSource.create(name: %w[VBMS VVA].sample, manifest: manifest) }

    let!(:records) do
      [
        source.records.create(version_id: "1234", series_id: "4321"),
        source.records.create(version_id: "5678", series_id: "8765")
      ]
    end

    context "when VBMS/VVA requests are successful" do
      it "saves files in S3" do
        allow(S3Service).to receive(:store_file).and_return(nil)
        V2::SaveFilesInS3Job.perform_now(source)
        expect(S3Service).to have_received(:store_file).twice
      end
    end

    context "when VBMS/VVA requests are not successful" do
      it "does not save files in S3" do
        allow(S3Service).to receive(:store_file).and_return(nil)
        allow(Caseflow::Fakes::DocumentService).to receive(:v2_fetch_document_file).and_raise([VBMS::ClientError, VVA::ClientError].sample)
        V2::SaveFilesInS3Job.perform_now(source)
        expect(S3Service).to_not have_received(:store_file)
      end
    end
  end
end
