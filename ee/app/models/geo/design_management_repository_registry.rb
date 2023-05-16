# frozen_string_literal: true

module Geo
  class DesignManagementRepositoryRegistry < Geo::BaseRegistry
    include ::Geo::ReplicableRegistry
    include ::Geo::VerifiableRegistry

    MODEL_CLASS = ::DesignManagement::Repository
    MODEL_FOREIGN_KEY = :design_management_repository_id

    belongs_to :design_management_repository, class_name: 'DesignManagement::Repository'
  end
end
