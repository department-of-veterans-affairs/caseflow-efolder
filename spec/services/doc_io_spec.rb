require 'rails_helper'
require 'zip'

describe DocIo do
  context "#save_encrypted" do
    it "saves and retrieves consistently" do
      str = "file save test"
      io = DocIo.new
      location = io.save_encrypted(str.bytes)
      retrieved = io.retrieve_decrypted(location).pack("U*")
      File.delete(location)
      expect(retrieved).to eq(str)
    end
  end

end

describe DocEncryption do
  let(:enc) { DocEncryption.random }

  context "#decrypt" do
    it "encrypts/decrypts consistently" do
      str = "enc test"
      encrypted = enc.encrypt(str)
      decrypted = enc.decrypt(encrypted)
      expect(decrypted).to eq(str)
    end
  end
end