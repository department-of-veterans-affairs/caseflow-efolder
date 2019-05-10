class DocumentCounter
  include ActiveModel::Model

  attr_accessor :manifest

  def count
    total = 0
    manifest.sources.each do |source|
      documents = ManifestFetcher.new(manifest_source: source).fetch_documents
      total += DocumentCreator.new(external_documents: documents).external_documents.count
    end
    total
  end
end
