# frozen_string_literal: true

class SensitivityChecker
  def sensitivity_levels_compatible?(user:, veteran_file_number:)
    bgs_service.sensitivity_level_for_user(user) >=
      bgs_service.sensitivity_level_for_veteran(veteran_file_number)
  rescue StandardError => e
    ExceptionLogger.capture(e)

    false
  end

  private

  def bgs_service
    @bgs_service ||= BGSService.new
  end
end
