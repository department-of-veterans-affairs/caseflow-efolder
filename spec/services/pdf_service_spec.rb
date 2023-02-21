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

  

   context "#optimize_pdf" do
    
      IO.binwrite("lib/pdfs/test2.pdf", IO.binread("lib/pdfs/0.pdf"))
      testpdf2 = "lib/pdfs/test2.pdf"
      testpdf2_size_before = File.size("lib/pdfs/test2.pdf")

     it "optimizes the pdf" do
      expect(File.exists?(testpdf2)).to be true
      PdfService.optimize(testpdf2)
      expect(File.size("lib/pdfs/test2.pdf")).to be < testpdf2_size_before
     end

     after(:context) do
      system("rm #{testpdf2}")
    end
   end
  
end
