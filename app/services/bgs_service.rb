class BGSService
  def self.new
    !BaseController.dependencies_faked? ? ExternalApi::BGSService.new : Fakes::BGSService.new
  end
end
