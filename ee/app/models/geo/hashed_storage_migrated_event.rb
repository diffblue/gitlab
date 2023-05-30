# frozen_string_literal: true

module Geo
  class HashedStorageMigratedEvent < ApplicationRecord
    include Geo::Model
    include Geo::Eventable

    belongs_to :project

    validates :project, :repository_storage_name,
      :old_disk_path, :new_disk_path, :old_wiki_disk_path,
      :new_wiki_disk_path, :new_storage_version, presence: true
  end
end
