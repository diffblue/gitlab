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
          {
            name: policy[:name],
            description: policy[:description],
            enabled: policy[:enabled],
            yaml: YAML.dump(policy.deep_stringify_keys),
            updated_at: policy_configuration.policy_last_updated_at
          }
        end
      end
    end
  end
end
