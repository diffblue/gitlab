# frozen_string_literal: true

module Resolvers
  module SecurityOrchestration
    class ScanExecutionPolicyResolver < BaseResolver
      include ResolvesOrchestrationPolicy

      POLICY_YAML_ATTRIBUTES = %i[name description enabled actions rules].freeze

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
        policies = fetch_scan_execution_policies(args[:relationship])
        policies = filter_scan_types(policies, args[:action_scan_types]) if args[:action_scan_types]
        policies.map do |policy|
          {
            name: policy[:name],
            description: policy[:description],
            enabled: policy[:enabled],
            yaml: YAML.dump(policy.slice(*POLICY_YAML_ATTRIBUTES).deep_stringify_keys),
            updated_at: policy_configuration.policy_last_updated_at,
            source: {
              project: policy[:project],
              namespace: policy[:namespace],
              inherited: policy[:inherited]
            }
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
