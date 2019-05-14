class DocumentCounter
  include ActiveModel::Model

  attr_accessor :manifest, :veteran

  def count
    total = 0
    services.each do |service|
      documents = service.v2_fetch_documents_for(manifest || veteran)
      total += DocumentFilter.new(documents: documents).filter.count
    end
    total
  end

  private

  def services
    return manifest.sources.map(&:service) if manifest
    return [VBMSService, VVAService] if veteran
    []
  end
end
