# frozen_string_literal: true
Rails.application.reloader.to_prepare do
  VeteranFileFetcher = ExternalApi::VeteranFileFetcher
    .new(use_canned_api_responses: BaseController.dependencies_faked_for_CEAPI?, logger: Rails.logger)
end