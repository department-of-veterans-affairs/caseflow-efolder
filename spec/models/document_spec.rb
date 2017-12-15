require "rails_helper"

describe Document do
  before do
    Rails.cache.clear
    Timecop.freeze(Time.utc(2015, 1, 1, 17, 0, 0))
  end

  let(:mime_type) { "application/pdf" }
  let(:download) { Download.create(file_number: "21012") }
  let(:document) do
    download.documents.build(
      document_id: "{3333-3333}",
      received_at: Time.utc(2015, 9, 6, 1, 0, 0),
      type_id: "825",
      mime_type: mime_type
    )
  end

  let(:txt_document) do
    download.documents.build(
      document_id: "{4444-4444}",
      received_at: Time.utc(2016, 2, 2, 1, 0, 0),
      type_id: "825",
      mime_type: "text/plain"
    )
  end

  context ".new" do
    context "vbms_filename" do
      subject { Document.new }

      it "defaults to empty string" do
        expect(subject.vbms_filename).to eq("")
      end
    end

    context "mime_type" do
      subject { Document.new(mime_type: mime_type).mime_type }

      context "should not update mime_type on initialize" do
        let(:mime_type) { "application/octet-stream" }
        it { is_expected.to eq("application/octet-stream") }
      end
    end
  end

  context ".create" do
    context "mime_type" do
      subject { Document.create(mime_type: mime_type).mime_type }

      context "if application/octet-stream" do
        let(:mime_type) { "application/octet-stream" }

        it { is_expected.to eq("application/pdf") }
      end
    end
  end

  context "#s3_filename" do
    subject { document.s3_filename }

    let(:document) do
      Document.new(id: 5, document_id: "{TEST}", mime_type: "application/pdf", download_id: 45)
    end

    it { is_expected.to eq("{TEST}.pdf") }
  end

  context "#filename" do
    subject { document.filename }

    context "all the components are present" do
      let(:document) do
        Document.new(
          vbms_filename: "purple.txt",
          received_at: Time.utc(2015, 1, 3, 17, 0, 0),
          type_id: "89",
          document_id: "{ABC123-DEF123-GHI456}",
          mime_type: "application/pdf"
        )
      end

      it { is_expected.to eq("STR-20150103-ABC123-DEF123-GHI456.pdf") }
    end

    context "when filename length equals 100" do
      let(:document) do
        Document.new(
          vbms_filename: "purple.txt",
          received_at: Time.utc(2015, 1, 3, 17, 0, 0),
          type_id: "497",
          document_id: "{ABC123-DEF123-GHI456A}",
          mime_type: "application/pdf"
        )
      end

      it { is_expected.to eq("VA 27-0820b Report of Nursing Home or Assisted Living Information-20150103-ABC123-DEF123-GHI456A.pdf") }
    end

    context "when filename length is greater than 100 (101)" do
      let(:document) do
        Document.new(
          vbms_filename: "purple.txt",
          received_at: Time.utc(2015, 1, 3, 17, 0, 0),
          type_id: "497",
          document_id: "{ABC123-DEF123-GHI456AB}",
          mime_type: "application/pdf"
        )
      end

      it { is_expected.to eq("VA 27-0820b Report of Nursing Home or Assisted Living Informatio-20150103-ABC123-DEF123-GHI456AB.pdf") }
    end
  end

  context ".average_download_rate" do
    subject { Document.calculate_historical_average_download_rate }
    before do
      @documents = []
      5.times do
        # 3 minute average
        @documents << Document.new(started_at: 4.minutes.ago,
                                   completed_at: 1.minute.ago,
                                   download_status: :success)
      end

      5.times do
        # 5 minutes average
        @documents << Document.new(started_at: 10.minutes.ago,
                                   completed_at: 5.minutes.ago,
                                   download_status: :success)
      end
    end

    it "properly calculates" do
      expect(Document.calculate_average_download_rate(@documents)).to eq(4.minutes.round(2))
    end
  end

  context ".calculate_historical_average_download_rate" do
    before do
      # 6 minute average
      Document.create!(started_at: 7.minutes.ago,
                       completed_at: 1.minute.ago,
                       download_status: :success)
    end

    context ".calculate_historical_average_download_rate" do
      subject { Document.calculate_historical_average_download_rate }

      it { is_expected.to eq(6.minutes.round(2)) }
    end
  end

  context ".calculate_and_save_historical_average_download_rate!" do
    before do
      # 6 minute average
      Document.create!(started_at: 7.minutes.ago,
                       completed_at: 1.minute.ago,
                       download_status: :success)
    end

    it "saves values to cache" do
      expect(Rails.cache.read(Document::AVERAGE_DOWNLOAD_RATE_CACHE_KEY)).to be_nil
      Document.calculate_and_save_historical_average_download_rate!
      cache_obj = Rails.cache.read(Document::AVERAGE_DOWNLOAD_RATE_CACHE_KEY)
      expect(cache_obj).to_not be_nil
      expect(cache_obj[:updated_at]).to eq(TimeUtil.floor(Document::AVERAGE_DOWNLOAD_RATE_CACHE_EXPIRATION))
      expect(cache_obj[:value]).to eq(6.minutes.round(2))
    end
  end

  context ".historical_average_download_rate" do
    subject { Document.historical_average_download_rate }
    let(:rails_cache) { Rails.cache }
    before do
      @rails_cache_write_called = false
    end

    it "reads value from cache" do
      Rails.cache.write(Document::AVERAGE_DOWNLOAD_RATE_CACHE_KEY,
                        updated_at: Time.zone.now,
                        value: 1234)

      expect(subject).to eq(1234)
      expect(@rails_cache_write_called).to be_falsey
    end

    it "writes value to cache" do
      # Write old values to catch
      Rails.cache.write(Document::AVERAGE_DOWNLOAD_RATE_CACHE_KEY,
                        updated_at: 30.seconds.ago,
                        value: 1234)
      Document.create!(started_at: 4.minutes.ago,
                       completed_at: 1.minute.ago,
                       download_status: :success)

      # Initial call, saving value to cahce
      expect(subject).to eq(3.minutes.round(2))
    end
  end

  context "#can_be_access_by?" do
    let(:user) { User.create(css_id: "123", station_id: "456") }
    let(:user_without_download) { User.create(css_id: "789", station_id: "456") }
    let(:download) do
      Download.create(
        file_number: "21012",
        user: user
      )
    end

    it "returns true when corresponding download has the passed in user." do
      expect(document.can_be_access_by?(user)).to eq(true)
    end

    it "returns false when corresponding download does not have the passed in user." do
      expect(document.can_be_access_by?(user_without_download)).to eq(false)
    end
  end

  context "#save_locally" do
    before do
      # clean files
      FileUtils.rm_rf(Rails.application.config.download_filepath)
    end

    it "creates a file in the correct directory and returns filename" do
      file_contents = IO.binread(Rails.root + "spec/support/test.pdf")
      document.save!
      document.save_locally(file_contents)
      expected_filepath = Rails.root + "tmp/files/#{download.id}/#{document.id}"
      expect(File.exist?(expected_filepath)).to be_truthy
      expect(document.path).to eq(expected_filepath.to_s)
    end

    it "handles non-pdf files correctly" do
      txt_document.save!
      txt_document.save_locally("Howdy")
      expect(IO.read(txt_document.path)).to eq("Howdy")
    end
  end

  context "#preferred_extension" do
    it "when passed application/pdf returns pdf" do
      expect(document.preferred_extension).to eq("pdf")
    end

    context "when passed image/tiff" do
      let(:mime_type) { "image/tiff" }
      it "returns pdf" do
        expect(document.preferred_extension).to eq("pdf")
      end
    end

    context "when passed image/jpeg" do
      let(:mime_type) { "image/jpeg" }
      it "returns jpeg" do
        expect(document.preferred_extension).to eq("jpeg")
      end
    end
  end
end
