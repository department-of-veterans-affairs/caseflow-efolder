require 'caseflow'

VBMSService = (!BaseController.dependencies_faked? ?  Efolder::ExternalApi::VBMSService : Fakes::VBMSService)
