# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class FetchPolicyService
      include BaseServiceUtility

      def initialize(policy_configuration:, name:, type:)
        @policy_configuration = policy_configuration
        @name = name
        @type = type
      end

      def execute
        success({ policy: policy })
      end

      private

      attr_reader :policy_configuration, :type, :name

      def policy
        policy_configuration
          .policy_by_type(type)
          .find { |policy| policy[:name] == name }
      end
    end
  end
end
