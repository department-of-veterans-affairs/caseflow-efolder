class BGSService
  def self.new(args = {})
    !BaseController.dependencies_faked? ? ExternalApi::BGSService.new(args) : Fakes::BGSService.new(args)
  end
end
