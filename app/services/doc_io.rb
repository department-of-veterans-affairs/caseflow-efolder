require 'openssl'
require 'Base64'
require 'tempfile'
require 'securerandom'
require 'zip'

class DocIo

  def initialize(opts = {})
    @encryption = opts.has_key?(:encryption_key) ?
        DocEncryption.new(opts[:encryption_key]) :
        DocEncryption.random
    @download_dir_base = opts[:download_dir_base] || Dir.tmpdir

    Dir.mkdir(@download_dir_base) unless File.exists?(@download_dir_base)
  end

  def save_encrypted(contents_bytes)
    encrypted_contents_hex = @encryption.encrypt(contents_bytes.pack("U*")).unpack("H*").first
    save(encrypted_contents_hex)
  end

  def retrieve_decrypted(path)
    encrypted_contents_hex = retrieve(path)
    encrypted_contents = [encrypted_contents_hex].pack('H*')
    @encryption.decrypt(encrypted_contents).bytes
  end

  private

  def save(contents)
    path = File.join(@download_dir_base, SecureRandom.uuid)
    File.write(path, contents)
    path
  end

  def retrieve(path)
    File.read(path)
  end

end

class DocEncryption

  def self.random
    DocEncryption.new(DocEncryption.new_cipher.random_key)
  end

  def initialize(key)
    @key = key

    # TODO: can use an iv per encryption if we store it in db
    @iv = key.reverse
  end

  def encrypt(contents_str)
    cipher = DocEncryption.new_cipher
    cipher.encrypt
    cipher.iv = @iv
    cipher.key = @key

    cipher.update(contents_str) + cipher.final
  end

  def self.new_cipher
    OpenSSL::Cipher.new('AES-128-CBC')
  end

  def decrypt(contents_str)
    decipher = DocEncryption.new_cipher
    decipher.decrypt
    decipher.iv = @iv
    decipher.key = @key
    decipher.update(contents_str) + decipher.final
  end
end