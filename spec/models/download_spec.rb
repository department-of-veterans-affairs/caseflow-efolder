describe "Download" do
  let(:download) { Download.create }

  context "#s3_filename" do
    subject { download.s3_filename }
    it { is_expected.to eq("#{download.id}-download.zip") }
  end

  context "#stalled?" do
    before { Timecop.freeze }
    after { Timecop.return }
    subject { download.stalled? }

    context "when not pending_documents" do
      before { download.status = :packaging_contents }
      it { is_expected.to be_falsey }
    end

    context "when pending_documents" do
      before { download.status = :pending_documents }

      context "when no pending documents have been started" do
        before do
          download.documents.create(download_status: :success)
          download.documents.create(download_status: :pending)
        end

        it { is_expected.to be_truthy }
      end

      context "when most recent pending document started before the threshold" do
        before do
          download.documents.create(download_status: :pending, started_at: 11.minutes.ago)
        end

        it { is_expected.to be_truthy }
      end

      context "when most recent document started after the threshold" do
        before do
          download.documents.create(download_status: :pending, started_at: 9.minutes.ago)
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  context "#progress_percentage" do
    subject { download.progress_percentage }

    context "when download is fetching_manifest" do
      before { download.status = :fetching_manifest }
      it { is_expected.to eq(20) }
    end

    context "when pending_documents" do
      before do
        download.status = :pending_documents
        @document1 = download.documents.create(document_id: "1")
        @document2 = download.documents.create(document_id: "2")
        @document3 = download.documents.create(document_id: "3")
      end

      context "when all documents are pending" do
        it { is_expected.to eq(40) }
      end

      context "when some documents are complete" do
        before { @document1.download_status = :success }
        it { is_expected.to eq(60) }
      end
    end

    context "when complete" do
      before { download.status = :complete }
      it { is_expected.to eq(100) }
    end

    context "when no_documents" do
      before { download.status = :no_documents }
      it { is_expected.to eq(100) }
    end
  end
end
