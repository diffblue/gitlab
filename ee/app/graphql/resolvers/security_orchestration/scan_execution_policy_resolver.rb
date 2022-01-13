# frozen_string_literal: true

module Resolvers
  module SecurityOrchestration
    class ScanExecutionPolicyResolver < BaseResolver
      include ResolvesOrchestrationPolicy

      type Types::SecurityOrchestration::ScanExecutionPolicyType, null: true

      argument :action_scan_types, [::Types::Security::ReportTypeEnum],
             description: "Filters policies by the action scan type. "\
                          "Only these scan types are supported: #{::Security::ScanExecutionPolicy::SCAN_TYPES.map { |type| "`#{type}`" }.join(', ')}.",
             required: false

      def resolve(**args)
        return [] unless valid?

        authorize!

        policies = policy_configuration.scan_execution_policy
        policies = filter_scan_types(policies, args[:action_scan_types]) if args[:action_scan_types]
        policies.map do |policy|
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

      def filter_scan_types(policies, scan_types)
        policies.filter do |policy|
          policy_scan_types = policy[:actions].map { |action| action[:scan].to_sym }
          (scan_types & policy_scan_types).present?
        end
      end
    end
  end
end
