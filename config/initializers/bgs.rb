# Wrapper required for depreciation warning fix as of 6.1
# See the link below for more details
# https://bill.harding.blog/2021/07/22/rails-6-1-deprecation-warning-initialization-autoloaded-the-constants-what-to-do-about-it/

Rails.application.reloader.to_prepare do
  BGSService = (!BaseController.dependencies_faked? ? ExternalApi::BGSService : Fakes::BGSService)
end