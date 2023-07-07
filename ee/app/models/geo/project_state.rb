# frozen_string_literal: true

module Geo
  class ProjectState < ApplicationRecord
    include ::Geo::VerificationStateDefinition

    belongs_to :project, inverse_of: :project_state

    validates :verification_state, :project, presence: true
  end
end
