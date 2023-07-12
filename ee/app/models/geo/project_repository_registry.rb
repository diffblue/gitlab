# frozen_string_literal: true

module Geo
  class ProjectRepositoryRegistry < Geo::BaseRegistry
    include IgnorableColumns
    include ::Geo::ReplicableRegistry
    include ::Geo::VerifiableRegistry

    MODEL_CLASS = ::Project
    MODEL_FOREIGN_KEY = :project_id

    ignore_column :force_to_redownload, remove_with: '16.4', remove_after: '2023-08-22'

    belongs_to :project, class_name: 'Project'
  end
end
