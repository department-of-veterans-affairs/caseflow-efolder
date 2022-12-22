class DocumentCreator
  include ActiveModel::Model

  attr_accessor :manifest_source
  attr_writer :external_documents

  def create
    ManifestSource.transaction do
      ft_delta_documents = FeatureToggle.enabled?(:cache_delta_documents, user: current_user)
      Rails.logger.info("Feature Toggle Cache Delta Documents Enabled? #{ft_delta_documents} for CSS ID: #{current_user&.css_id}")
      if ft_delta_documents
        external_documents.uniq(&:document_id).map do |document|
          manifest_source.current? ? manifest_source.records.where(series_id: document.series_id).destroy_all : manifest_source.records.destroy_all
          Record.create_from_external_document(manifest_source, document)
        end
      else
        # Re-create documents each time in order to use the latest versions
        # and if documents were deleted from VBMS
        manifest_source.records.delete_all
        # Remove any duplicates before adding them.
        external_documents.uniq(&:document_id).map do |document|
          Record.create_from_external_document(manifest_source, document)
        end
      end
    end
  rescue ActiveRecord::RecordNotUnique
    # This can happen when two jobs are run simultaneously. Both jobs delete the records
    # then the first job adds all the records and finishes its transaction. The records are
    # committed so when the second job then tries to add the same documents, it encounters
    # the unique constraint on the table and an error is raised.
    #
    # We can ignore this exception because the race condition that causes it
    # means that another thread just created these records.
    Rails.logger.info "ActiveRecord::RecordNotUnique thrown for ManifestSource #{manifest_source.id}"
  end

  # Override the getter to return only non-restricted documents
  def external_documents
    DocumentFilter.new(documents: @external_documents).filter
  end

  private

  def current_user
    RequestStore[:current_user]
  end
end
