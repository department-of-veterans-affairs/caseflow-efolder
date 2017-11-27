describe User do
  let(:name) { "Billy Bob Thorton" }
  let(:roles) { ["Download eFolder"] }
  let(:user) do
    User.new(css_id: "123", email: "email@va.gov", name: name,
             roles: roles, station_id: "213", ip_address: "12.12.12.12")
  end

  before { User.stub = nil }

  context "#display_name" do
    subject { user.display_name }
    context "when name" do
      it { is_expected.to eq("Billy Bob Thorton") }
    end

    context "when no name" do
      let(:name) { nil }
      it { is_expected.to eq("Unknown") }
    end
  end

  context "#can?" do
    subject { user.can?(action) }

    context "when roles are nil" do
      let(:roles) { nil }
      let(:action) { "Download eFolder" }
      it { is_expected.to be_falsey }
    end

    context "when user's roles contain action" do
      let(:action) { "Download eFolder" }
      it { is_expected.to be_truthy }
    end

    context "when user's roles don't contain action" do
      let(:action) { "System Admin" }
      it { is_expected.to be_falsey }
    end
  end

  context "save" do
    let(:css_id) { Random.rand(9_999) + 1 }
    let(:station_id) { Random.rand(499) + 1 }
    let(:email_without_spaces) { "king_bongo@zombo.com" }
    let(:email) { "    #{email_without_spaces}   " }
    subject { User.create(email: email, css_id: css_id, station_id: station_id) }

    it "strips leading and trailing spaces from email address" do
      expect(subject.email).to eq(email_without_spaces)
    end

    context "when email is nil" do
      let(:email) { nil }
      it "saves to database without error" do
        expect(subject.email).to eq(nil)
      end
    end
  end

  context ".from_session" do
    let(:request) { OpenStruct.new(remote_ip: "123.123.222.222") }
    let(:session) { { "user" => user.as_json.merge("roles" => user.roles, "name" => user.name) } }
    subject { User.from_session(session, request) }

    it "returns a user from session and request" do
      expect(subject.name).to eq("Billy Bob Thorton")
      expect(subject.ip_address).to eq("123.123.222.222")
      expect(subject.email).to eq user.email
    end

    context "when session user is nil" do
      let(:session) { { "user" => nil } }
      it { is_expected.to be_nil }
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

    subject { User.from_css_auth_hash(auth_hash) }

    it "returns a user with the correct attributes" do
      expect(subject[:css_id]).to eq("UID")
      expect(subject[:name]).to eq("Kanye West")
      expect(subject[:email]).to eq("kanye@va.gov")
      expect(subject[:roles]).to eq(["Download eFolder"])
      expect(subject[:station_id]).to eq("123")
    end
  end
end
