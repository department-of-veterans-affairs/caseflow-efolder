# frozen_string_literal: true

VeteranFileFetcher = ExternalApi::VeteranFileFetcher
  .new(use_canned_api_responses: BaseController.dependencies_faked_for_CEAPI?, logger: Rails.logger)
