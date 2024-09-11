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
        expect { subject }.to raise_error(BGSErrors::InvalidUsername)
      end
    end

    context "invalid station id" do
      let(:station_id) { "invalid" }

      it "raises InvalidStation error" do
        expect { subject }.to raise_error(BGSErrors::InvalidStation)
      end
    end

    context "user has no stations active" do
      let(:username) { "zero-stations" }

      it "raises NoActiveStations error" do
        expect { subject }.to raise_error(BGSErrors::NoActiveStations)
      end
    end
  end
end
