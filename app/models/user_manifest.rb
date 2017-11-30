class UserManifest < ActiveRecord::Base
  belongs_to :user
  belongs_to :manifest

  validates :manifest, :user, presence: true
end
