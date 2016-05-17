class Fakes::BGSService
  cattr_accessor :veteran_names

  def self.fetch_veteran_name(file_number)
    veteran_names[file_number]
  end
end
