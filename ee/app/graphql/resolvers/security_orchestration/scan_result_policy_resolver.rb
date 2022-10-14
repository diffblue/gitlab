# frozen_string_literal: true

module Resolvers
  module SecurityOrchestration
    class ScanResultPolicyResolver < BaseResolver
      include ResolvesOrchestrationPolicy

      type Types::SecurityOrchestration::ScanResultPolicyType, null: true

      def resolve(**args)
        policies = Security::ScanResultPoliciesFinder.new(context[:current_user], project, args).execute
        policies.map do |policy|
          approvers = approvers(policy)
          {
            name: policy[:name],
            description: policy[:description],
            enabled: policy[:enabled],
            yaml: YAML.dump(policy.slice(*POLICY_YAML_ATTRIBUTES).deep_stringify_keys),
            updated_at: policy[:config].policy_last_updated_at,
            user_approvers: approvers[:users],
            group_approvers: approvers[:groups]
          }
        end
      end

      private

      def approvers(policy)
        Security::SecurityOrchestrationPolicies::FetchPolicyApproversService
          .new(policy: policy, container: project, current_user: context[:current_user])
          .execute
      end
    end
  end
end
