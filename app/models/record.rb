class Record < ActiveRecord::Base
  belongs_to :manifest_source

  validates :manifest_source, :external_document_id, presence: true
  validates :external_document_id, uniqueness: true

  def self.create_from_external_document(manifest_source, document)
    # TODO: add DB index for [manifest_source_id, external_document_id]
    find_or_initialize_by(manifest_source: manifest_source, external_document_id: document.document_id).tap do |t|
      t.assign_attributes(
        type_id: document.type_id,
        type_description: document.type_description,
        mime_type: document.mime_type,
        received_at: document.received_at,
        jro: document.jro,
        source: document.source
      )
      t.save!
    end
  end
end
