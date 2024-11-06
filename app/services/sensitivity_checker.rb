# frozen_string_literal: true

class SensitivityChecker
  def sensitivity_levels_compatible?(user:, veteran_file_number:)
    bgs_service.sensitivity_level_for_user(user) >=
      bgs_service.sensitivity_level_for_veteran(veteran_file_number)
  rescue StandardError => e
    report_error(e)

    false
  end

  def sensitivity_level_for_user(user)
    bgs_service.sensitivity_level_for_user(user)
  rescue StandardError => e
    report_error(e)

    nil
  end

  private

  def bgs_service
    @bgs_service ||= BGSService.new
  end

  def error_handler
    @error_handler ||= ErrorHandlers::ClaimEvidenceApiErrorHandler.new
  end

  def report_error(error)
    error_details = {
      user_css_id: RequestStore[:current_user]&.css_id || "User is not set in RequestStore",
      user_sensitivity_level: "Error occurred in SensitivityChecker",
      error_uuid: SecureRandom.uuid
    }
    error_handler.handle_error(error: error, error_details: error_details)
  end
end
