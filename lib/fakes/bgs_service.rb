class Fakes::BGSService
  cattr_accessor :veteran_info
  cattr_accessor :sensitive_files

  def self.fetch_veteran_info(file_number)
    if file_number =~ /DEMO/
      return { "veteran_first_name" => "Test",
               "veteran_last_name" => "User",
               "veteran_last_four_ssn" => "1224" }
    end
    (veteran_info || {})[file_number]
  end

  def self.check_sensitivity(file_number)
    !(sensitive_files || {})[file_number]
  end
end
