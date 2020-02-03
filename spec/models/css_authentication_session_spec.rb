describe CssAuthenticationSession do
  let(:id) { "VACOSOLOH" }
  let(:css_id) { "VACOSOLOH" }
  let(:email) { "Han.Solo@va.gov" }
  let(:name) { "Han Solo" }
  let(:roles) { "Reader" }
  let(:station_id) { "112" }
  let(:arguments) do
    { id: id,
      css_id: css_id,
      email: email,
      name: name,
      roles: roles,
      station_id: station_id }
  end

  context "when creating a new object via .new" do
    context "with a lowercase css_id" do
      let(:css_id) { "rey" }
      let(:uppercased_css_id) { "REY" }

      subject { CssAuthenticationSession.new(arguments) }

      it "uppercases the css_id" do
        expect(subject.css_id).to eq(uppercased_css_id)
      end
    end

    context "with an email address with leading and trailing spaces" do
      let(:email_without_spaces) { "jakkuloner@sw.org" }
      let(:email) { "    #{email_without_spaces}   " }

      subject { CssAuthenticationSession.new(arguments) }

      it "trims leading and trailing spaces from the email address" do
        expect(subject.email).to eq(email_without_spaces)
      end
    end
  end

  context ".from_css_auth_hash" do
    let(:auth_hash) do
      OpenStruct.new(
        uid: "UID",
        extra: OpenStruct.new(raw_info: auth_hash_data)
      )
    end

    let(:auth_hash_data) do
      data = {
        "http://vba.va.gov/css/common/fName" => "Kanye",
        "http://vba.va.gov/css/common/lName" => "West",
        "http://vba.va.gov/css/common/emailAddress" => "kanye@va.gov",
        "http://vba.va.gov/css/common/stationId" => "123"
      }

      data.define_singleton_method(:attributes) do
        { "http://vba.va.gov/css/caseflow/role" => ["Download eFolder"] }
      end

      data
    end

    subject { CssAuthenticationSession.from_css_auth_hash(auth_hash) }

    it "returns a user with the correct attributes" do
      expect(subject.css_id).to eq("UID")
      expect(subject.name).to eq("Kanye West")
      expect(subject.email).to eq("kanye@va.gov")
      expect(subject.roles).to eq(["Download eFolder"])
      expect(subject.station_id).to eq("123")
    end
  end

  describe ".from_iam_auth_hash" do
    let(:auth_hash) do
      OpenStruct.new(extra: OpenStruct.new(raw_info: { adSamAccountName: saml_username }))
    end

    let(:username) { nil }
    let(:saml_username) { nil }
    let(:station_id) { nil }

    subject { described_class.from_iam_auth_hash(auth_hash, username, station_id) }

    context "username defined in SAML payload" do
      let(:saml_username) { "as reported from SAML" }

      it "parses authz from BGS" do
        expect(subject.email).to eq "first.last@test.gov"
        expect(subject.css_id).to eq "BVALASTFIRST"
        expect(subject.name).to eq "First Last"
      end
    end

    context "invalid username" do
      let(:username) { "invalid" }

      it "raises InvalidUsername error" do
        expect { subject }.to raise_error(BGS::InvalidUsername)
      end
    end

    context "invalid station id" do
      let(:station_id) { "invalid" }

      it "raises InvalidStation error" do
        expect { subject }.to raise_error(BGS::InvalidStation)
      end
    end

    context "user has no stations active" do
      let(:username) { "zero-stations" }

      it "raises NoActiveStations error" do
        expect { subject }.to raise_error(BGS::NoActiveStations)
      end
    end
  end
end
