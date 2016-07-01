describe "Download" do
  let(:download) { Download.create }
  before { Timecop.freeze }
  after { Timecop.return }

  context "#s3_filename" do
    subject { download.s3_filename }
    it { is_expected.to eq("#{download.id}-download.zip") }
  end

  context "#stalled?" do
    subject { download.stalled? }

    context "when not pending_documents" do
      before { download.status = :packaging_contents }
      it { is_expected.to be_falsey }
    end

    context "when pending_documents" do
      before { download.status = :pending_documents }

      context "when last updated after the threshold" do
        before do
          download.update_attributes(updated_at: 11.minutes.ago)
        end

        it { is_expected.to be_truthy }
      end

      context "when most recent pending document started before the threshold" do
        before do
          download.update_attributes(updated_at: 9.minutes.ago)
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  context "#estimated_to_complete_at" do
    before { download.documents.create!(started_at: 1.minute.ago) }
    subject { download.estimated_to_complete_at }
    let(:document) { download.documents.first }

    context "when download is fetching manifest" do
      before { download.update_attributes!(status: :fetching_manifest) }
      it { is_expected.to be_nil }
    end

    context "when download is pending documents" do
      before { download.update_attributes!(status: :pending_documents) }

      context "when no documents have been downloaded" do
        before { document.update_attributes(started_at: Time.zone.now) }
        it { is_expected.to be_nil }
      end

      context "when a documents have been downloaded" do
        before do
          download.documents.create!(started_at: 3.minutes.ago, completed_at: 1.minute.ago)
        end

        it "calculates correctly with one download" do
          expect(subject).to eq(1.minute.from_now)
        end

        it "calculates correctly with two downloads completed" do
          download.documents.create!(started_at: 7.minutes.ago, completed_at: 3.minutes.ago)
          expect(subject).to eq(2.minutes.from_now)
        end

        it "calculates corrrectly with two downloads left" do
          download.documents.create!
          expect(subject).to eq(3.minutes.from_now)
        end
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
