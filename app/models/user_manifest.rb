# frozen_string_literal: true

class UserManifest < ApplicationRecord
  belongs_to :user
  belongs_to :manifest

  validates :manifest, :user, presence: true
end
