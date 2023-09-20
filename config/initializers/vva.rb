Rails.application.reloader.to_prepare do
  VVAService = (!BaseController.dependencies_faked? ? ExternalApi::VVAService : Fakes::VVAService)
end