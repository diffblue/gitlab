# frozen_string_literal: true

module Geo
  class DesignManagementRepositoryRegistry < Geo::BaseRegistry
    include IgnorableColumns
    include ::Geo::ReplicableRegistry
    include ::Geo::VerifiableRegistry

    MODEL_CLASS = ::DesignManagement::Repository
    MODEL_FOREIGN_KEY = :design_management_repository_id

    ignore_column :force_to_redownload, remove_with: '16.4', remove_after: '2023-08-22'

    belongs_to :design_management_repository, class_name: 'DesignManagement::Repository'
  end
end
