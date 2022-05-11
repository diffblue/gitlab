# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class PolicyConfigurationValidationService
      include BaseServiceUtility

      def initialize(policy_configuration:, type:)
        @policy_configuration = policy_configuration
        @type = type
      end

      def execute
        return error_response(_('type parameter is missing and is required'), :parameter) unless @type
        return error_response(_('Invalid policy type'), :parameter) unless valid_type?

        return error_response(_('Project does not have a policy configuration'), :policy_configuration) if policy_configuration.nil?

        unless policy_configuration.policy_configuration_exists?
          return error_response(
            _("Policy management project does not have any policies in %{policy_path}" % {
              policy_path: ::Security::OrchestrationPolicyConfiguration::POLICY_PATH
            }),
            :policy_project
          )
        end

        unless policy_configuration.policy_configuration_valid?
          return error_response(_('Could not fetch policy because existing policy YAML is invalid'), :policy_yaml)
        end

        success
      end

      private

      attr_reader :policy_configuration, :type

      def error_response(message, invalid_component)
        error(message, pass_back: { invalid_component: invalid_component })
      end

      def valid_type?
        Security::OrchestrationPolicyConfiguration::AVAILABLE_POLICY_TYPES.include?(type)
      end
    end
  end
end
