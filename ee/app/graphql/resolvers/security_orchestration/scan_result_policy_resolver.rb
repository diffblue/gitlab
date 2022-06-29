# frozen_string_literal: true

module Resolvers
  module SecurityOrchestration
    class ScanResultPolicyResolver < BaseResolver
      include ResolvesOrchestrationPolicy

      type Types::SecurityOrchestration::ScanResultPolicyType, null: true

      def resolve(**args)
        return [] unless valid?

        authorize!

        policy_configuration.scan_result_policies.map do |policy|
          approvers = approvers(policy)
          {
            name: policy[:name],
            description: policy[:description],
            enabled: policy[:enabled],
            yaml: YAML.dump(policy.deep_stringify_keys),
            updated_at: policy_configuration.policy_last_updated_at,
            user_approvers: approvers[:users],
            group_approvers: approvers[:groups]
          }
        end
      end

      private

      def approvers(policy)
        Security::SecurityOrchestrationPolicies::FetchPolicyApproversService
          .new(policy: policy, project: project, current_user: context[:current_user])
          .execute
      end
    end
  end
end
