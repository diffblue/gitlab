# frozen_string_literal: true

module EE
  module DeploymentPolicy
    extend ActiveSupport::Concern

    prepended do
      condition(:protected_environment) do
        @subject.environment.protected_from?(user)
      end

      condition(:needs_approval) do
        @subject.environment.needs_approval?
      end

      condition(:has_approval_rules) do
        @subject.environment.has_approval_rules?
      end

      condition(:approval_rule_for_user) do
        @subject.environment.find_approval_rule_for(user).present?
      end

      rule { protected_environment }.policy do
        prevent :destroy_deployment
      end

      rule { needs_approval & ~has_approval_rules & can?(:update_deployment) }.policy do
        enable :approve_deployment
      end

      rule { needs_approval & has_approval_rules & can?(:read_deployment) & approval_rule_for_user }.policy do
        enable :approve_deployment
      end
    end
  end
end
