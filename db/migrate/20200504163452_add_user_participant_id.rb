class AddUserParticipantId < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :participant_id, :string
  end
end
