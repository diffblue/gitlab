# frozen_string_literal: true

module EE
  module DeploymentPolicy
    extend ActiveSupport::Concern

    prepended do
      condition(:protected_environment) do
        @subject.environment.protected_from?(user)
      end

      rule { protected_environment }.policy do
        prevent :destroy_deployment
      end
    end
  end
end
