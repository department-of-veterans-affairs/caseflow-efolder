require 'caseflow'

VBMSService = (!BaseController.dependencies_faked? ? Caseflow::ExternalApi::VBMSService : Fakes::VBMSService)
