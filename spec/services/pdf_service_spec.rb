describe PdfService do
  context "#write_attributes_file" do
    let(:pdf_attributes) do
      {
        "Name": "Joe",
        "Document Type": "Form-9"
      }
    end

    it "writes attributes file" do
      file = PdfService.write_attributes_file(pdf_attributes)
      expect(IO.read(file.path)).to eq(<<-EOF.strip_heredoc
        InfoBegin
        InfoKey: Name
        InfoValue: Joe
        InfoBegin
        InfoKey: Document Type
        InfoValue: Form-9
        EOF
                                      )
    end
  end

  context "#write" do
    it "writes raw bytes on pdftk failure" do
      filename = PdfService.write("test", "plain text", "Name" => "Joe")
      expect(IO.read(filename)).to eq("plain text")
    end
  end
end
