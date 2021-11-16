# frozen_string_literal: true

module Resolvers
  class ScanExecutionPolicyResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    calls_gitaly!
    type Types::ScanExecutionPolicyType, null: true

    alias_method :project, :object

    argument :action_scan_types, [::Types::Security::ReportTypeEnum],
             description: "Filters policies by the action scan type. "\
                          "Only these scan types are supported: #{Security::ScanExecutionPolicy::SCAN_TYPES.map { |type| "`#{type}`" }.join(', ')}.",
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

    def authorize!
      Ability.allowed?(
        context[:current_user], :security_orchestration_policies, policy_configuration.security_policy_management_project
      ) || raise_resource_not_available_error!
    end

    def policy_configuration
      @policy_configuration ||= project.security_orchestration_policy_configuration
    end

    def filter_scan_types(policies, scan_types)
      policies.filter do |policy|
        policy_scan_types = policy[:actions].map { |action| action[:scan].to_sym }
        (scan_types & policy_scan_types).present?
      end
    end

    def valid?
      policy_configuration.present? && policy_configuration.policy_configuration_valid?
    end
  end
end
