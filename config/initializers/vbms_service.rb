Rails.application.reloader.to_prepare do
  VBMSService = (!BaseController.dependencies_faked? ? ExternalApi::VBMSService : Fakes::VBMSService)
end
