describe User do
  let(:name) { "Billy Bob Thorton" }
  let(:roles) { ["Download eFolder"] }
  let(:user) do
    User.new(css_id: "auser", email: "email@va.gov", name: name,
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

  context ".from_session_and_request" do
    let(:request) { OpenStruct.new(remote_ip: "123.123.222.222") }
    let(:session) do
      { "user" =>
        { "css_id" => user.css_id,
          "email" => user.email,
          "station_id" => user.station_id,
          "roles" => user.roles,
          "name" => user.name } }
    end
    subject { User.from_session_and_request(session, request) }

    it "returns a user from session and request" do
      expect(subject.name).to eq("Billy Bob Thorton")
      expect(subject.ip_address).to eq("123.123.222.222")
      expect(subject.email).to eq user.email
      expect(subject.css_id).to eq user.css_id.upcase
    end

    context "when session user is nil" do
      let(:session) { { "user" => nil } }
      it { is_expected.to be_nil }
    end

    context "when session user does not contain css_id" do
      let(:session) { { "user" => { "roles" => ["Certify Appeal", "Establish Claim"], "station_id" => "283", "email" => "america@example.com", "name" => "Cave Johnson" } } }
      it { is_expected.to be_nil }
    end
  end

  context ".from_api_authenticated_values" do
    let(:css_id) { "lowercase_id" }
    let(:uppercased_css_id) { "LOWERCASE_ID" }
    let(:station_id) { Random.rand(1..499) }

    context "when both css_id and station_id are defined" do
      subject { User.from_api_authenticated_values(css_id: css_id, station_id: station_id) }
      it "creates a new User object with an uppercase css_id" do
        expect(subject.id).not_to be_nil
        expect(subject.css_id).to eq(uppercased_css_id)
      end
    end
  end

  context "#css_record" do
    subject { described_class.new(css_id: "foobar", station_id: "101") }

    let(:bgs_service) { double("bgs") }
    let(:bgs_client) { double("client") }
    let(:bgs_security) { double("security") }
    let(:bgs_user_record) do
      {
        email_address: "foo@example.com",
        last_name: "Bar",
        participant_id: "123"
      }
    end

    before do
      allow(bgs_service).to receive(:client) { bgs_client }
      allow(bgs_client).to receive(:common_security) { bgs_security }
      allow(bgs_security).to receive(:get_security_profile).with(
        username: subject.css_id, station_id: subject.station_id, application: "CASEFLOW"
      ) { bgs_user_record }
      allow(subject).to receive(:bgs) { bgs_service }
    end

    it "returns CSS security profile" do
      expect(subject.css_record[:email_address]).to eq "foo@example.com"
      expect(subject.participant_id).to eq "123"
    end
  end
end
