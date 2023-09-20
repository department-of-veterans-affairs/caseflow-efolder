Rails.application.reloader.to_prepare do
  BGSService = (!BaseController.dependencies_faked? ? ExternalApi::BGSService : Fakes::BGSService)
end