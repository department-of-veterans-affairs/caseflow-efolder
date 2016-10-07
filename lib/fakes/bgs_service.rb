class Fakes::BGSService
  cattr_accessor :veteran_info
  cattr_accessor :sensitive_files

  def self.fetch_veteran_info(file_number)
    (veteran_info || {})[file_number]
  end

  def self.check_sensitivity(file_number)
    !(sensitive_files || {})[file_number]
  end
end
