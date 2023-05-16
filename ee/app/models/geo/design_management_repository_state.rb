# frozen_string_literal: true

module Geo
  class DesignManagementRepositoryState < ApplicationRecord
    include ::Geo::VerificationStateDefinition

    self.primary_key = :design_management_repository_id

    belongs_to :design_management_repository,
      inverse_of: :design_management_repository_state,
      class_name: 'DesignManagement::Repository'

    validates :verification_failure, length: { maximum: 255 }
    validates :verification_state, :design_management_repository, presence: true
  end
end
