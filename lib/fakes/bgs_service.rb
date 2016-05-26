class Fakes::BGSService
  cattr_accessor :veteran_names
  cattr_accessor :sensitive_files

  def self.fetch_veteran_name(file_number)
    veteran_names[file_number]
  end

  def self.check_sensitivity(file_number)
    !(sensitive_files || {})[file_number]
  end
end
