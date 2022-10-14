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

      argument :relationship, ::Types::SecurityOrchestration::SecurityPolicyRelationTypeEnum,
               description: 'Filter policies by the given policy relationship.',
               required: false,
               default_value: :direct

      def resolve(**args)
        policies = Security::ScanExecutionPoliciesFinder.new(context[:current_user], project, args).execute
        policies.map do |policy|
          {
            name: policy[:name],
            description: policy[:description],
            enabled: policy[:enabled],
            yaml: YAML.dump(policy.slice(*POLICY_YAML_ATTRIBUTES).deep_stringify_keys),
            updated_at: policy[:config].policy_last_updated_at,
            source: {
              project: policy[:project],
              namespace: policy[:namespace],
              inherited: policy[:inherited]
            }
          }
        end
      end
    end
  end
end
