describe AuthenticatedVisitor do
  let(:id) { "VACOSOLOH" }
  let(:css_id) { "VACOSOLOH" }
  let(:email) { "Han.Solo@va.gov" }
  let(:name) { "Han Solo" }
  let(:roles) { "Reader" }
  let(:station_id) { "122" }
  let(:arguments) do
    { id: id,
      css_id: css_id,
      email: email,
      name: name,
      roles: roles,
      station_id: station_id
    }
  end

  context "when creating a new object via .new" do
    context "with a lowercase css_id" do
      let(:css_id) { "rey" }
      let(:uppercased_css_id) { css_id.upcase }

      subject { AuthenticatedVisitor.new(arguments) }

      it "uppercases the css_id" do
        expect(subject.css_id).to eq(uppercased_css_id)
      end
    end

    context "with an email address with leading and trailing spaces" do
      let(:email_without_spaces) { "jakkuloner@sw.org" }
      let(:email) { "    #{email_without_spaces}   " }

      subject { AuthenticatedVisitor.new(arguments) }

      it "trims leading and trailing spaces from the email address" do
        expect(subject.email).to eq(email_without_spaces)
      end
    end
  end
end
