# frozen_string_literal: true

module Resolvers
  class ScanExecutionPolicyResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    calls_gitaly!
    type Types::ScanExecutionPolicyType, null: true

    alias_method :project, :object

    def resolve(**args)
      return [] unless enabled_and_valid?

      authorize!

      policy_configuration.scan_execution_policy.map do |policy|
        {
          name: policy[:name],
          description: policy[:description],
          enabled: policy[:enabled],
          yaml: YAML.dump(policy.deep_stringify_keys),
          updated_at: policy_configuration.policy_last_updated_at
        }
      end
    end

    private

    def authorize!
      Ability.allowed?(
        context[:current_user], :security_orchestration_policies, policy_configuration.security_policy_management_project
      ) || raise_resource_not_available_error!
    end

    def policy_configuration
      @policy_configuration ||= project.security_orchestration_policy_configuration
    end

    def enabled_and_valid?
      policy_configuration.present? && policy_configuration.enabled? && policy_configuration.policy_configuration_valid?
    end
  end
end
