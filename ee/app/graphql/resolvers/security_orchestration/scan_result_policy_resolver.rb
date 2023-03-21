# frozen_string_literal: true

module Resolvers
  module SecurityOrchestration
    class ScanResultPolicyResolver < BaseResolver
      include ResolvesOrchestrationPolicy

      type Types::SecurityOrchestration::ScanResultPolicyType, null: true

      argument :relationship, ::Types::SecurityOrchestration::SecurityPolicyRelationTypeEnum,
               description: 'Filter policies by the given policy relationship.',
               required: false,
               default_value: :direct

      def resolve(**args)
        policies = Security::ScanResultPoliciesFinder.new(context[:current_user], object, args).execute
        policies.map do |policy|
          approvers = approvers(policy)
          {
            name: policy[:name],
            description: policy[:description],
            enabled: policy[:enabled],
            yaml: YAML.dump(policy.slice(*POLICY_YAML_ATTRIBUTES).deep_stringify_keys),
            updated_at: policy[:config].policy_last_updated_at,
            user_approvers: approvers[:users],
            group_approvers: approvers[:groups],
            role_approvers: approvers[:roles],
            source: {
              project: policy[:project],
              namespace: policy[:namespace],
              inherited: policy[:inherited]
            }
          }
        end
      end

      private

      def approvers(policy)
        Security::SecurityOrchestrationPolicies::FetchPolicyApproversService
          .new(policy: policy, container: object, current_user: context[:current_user])
          .execute
      end
    end
  end
end
