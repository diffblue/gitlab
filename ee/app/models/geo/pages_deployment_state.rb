# frozen_string_literal: true

module Geo
  class PagesDeploymentState < ApplicationRecord
    include ::Geo::VerificationStateDefinition

    self.primary_key = :pages_deployment_id

    belongs_to :pages_deployment, inverse_of: :pages_deployment_state
  end
end
