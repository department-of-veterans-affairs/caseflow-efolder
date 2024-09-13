# frozen_string_literal: true

class FindValidVeteranFileNumbers
  def initialize(user: nil)
    fail "Non-prod only" unless Rails.non_production_env?

    self.current_user = user || User.system_user

    RequestStore.store[:current_user] = user
  end

  def run
    valid_file_numbers = {}
    invalid_file_numbers = []

    Manifest.all.find_each do |manifest|
      file_number = manifest.file_number

      begin
        level = bgs_service.sensitivity_level_for_veteran(file_number)

        key = "sensitivity_level_#{level}"
        if !valid_file_numbers.key?(key)
          valid_file_numbers[key] = []
        end

        valid_file_numbers[key].push(file_number)
      rescue RuntimeError => e
        invalid_file_numbers.push(manifest.file_number)
        continue
      end
    end

    display_final_result(valid_file_numbers, invalid_file_numbers)
  end

  private

  attr_accessor :current_user

  def display_final_result(valid_file_numbers, invalid_file_numbers)
    puts ""
    puts "================================================================================"

    puts "VALID FILE NUMBERS:"
    valid_file_numbers.each do |k, v|
      puts "#{k.upcase}"

      valid_file_numbers[k].each do |number|
        puts "- #{number}"
      end
    end

    puts "\nINVALID FILE NUMBERS:"
    invalid_file_numbers.each do |number|
      puts "- #{number}"
    end

    puts "================================================================================"
    puts ""
  end

  def bgs_service
    @bgs_service ||= BGSService.new
  end
end
