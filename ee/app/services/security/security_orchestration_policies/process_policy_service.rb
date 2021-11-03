# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class ProcessPolicyService
      def initialize(policy_configuration:, params:)
        @policy_configuration = policy_configuration
        @params = params
      end

      def execute
        policy = params[:policy]
        type = params[:type]
        name = params[:name]
        operation = params[:operation]

        raise StandardError, "Invalid policy type" unless Security::OrchestrationPolicyConfiguration::AVAILABLE_POLICY_TYPES.include?(type)
        raise StandardError, "Name should be same as the policy name" if name && operation != :replace && policy[:name] != name

        policy_hash = policy_configuration.policy_hash.dup || {}

        case operation
        when :append then append_to_policy_hash(policy_hash, policy, type)
        when :replace then replace_in_policy_hash(policy_hash, name, policy, type)
        when :remove then remove_from_policy_hash(policy_hash, policy, type)
        end

        raise StandardError, "Invalid policy yaml" unless policy_configuration.policy_configuration_valid?(policy_hash)

        policy_hash
      end

      private

      def append_to_policy_hash(policy_hash, policy, type)
        if policy_hash[type].blank?
          policy_hash[type] = [policy]
          return
        end

        raise StandardError, "Policy already exists with same name" if policy_exists?(policy_hash, policy[:name], type)

        policy_hash[type] += [policy]
      end

      def replace_in_policy_hash(policy_hash, name, policy, type)
        raise StandardError, "Policy already exists with same name" if name && name != policy[:name] && policy_exists?(policy_hash, policy[:name], type)

        existing_policy_index = check_if_policy_exists!(policy_hash, name || policy[:name], type)
        policy_hash[type][existing_policy_index] = policy
      end

      def remove_from_policy_hash(policy_hash, policy, type)
        check_if_policy_exists!(policy_hash, policy[:name], type)
        policy_hash[type].reject! { |p| p[:name] == policy[:name] }
      end

      def check_if_policy_exists!(policy_hash, policy_name, type)
        existing_policy_index = policy_exists?(policy_hash, policy_name, type)
        raise StandardError, "Policy does not exist" if existing_policy_index.nil?

        existing_policy_index
      end

      def policy_exists?(policy_hash, policy_name, type)
        policy_hash[type].find_index { |p| p[:name] == policy_name }
      end

      attr_reader :policy_configuration, :params
    end
  end
end
