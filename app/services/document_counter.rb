class DocumentCounter
  include ActiveModel::Model

  attr_accessor :manifest

  def count
    total = 0
    manifest.sources.each do |source|
      documents = ManifestFetcher.new(manifest_source: source).documents
      total += DocumentFilter.new(documents: documents).filter.count
    end
    total
  end
end
