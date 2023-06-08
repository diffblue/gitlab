# frozen_string_literal: true

module Geo
  class ContainerRepositoryState < ApplicationRecord
    include ::Geo::VerificationStateDefinition

    self.primary_key = :container_repository_id

    belongs_to :container_repository, inverse_of: :container_repository_state

    validates :verification_state, :container_repository, presence: true
  end
end
