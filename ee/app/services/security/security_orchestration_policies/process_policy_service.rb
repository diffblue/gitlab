# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class ProcessPolicyService
      include BaseServiceUtility

      Error = Class.new(StandardError)

      def initialize(policy_configuration:, params:)
        @policy_configuration = policy_configuration
        @params = params
      end

      def execute
        policy = params[:policy]
        type = params[:type]
        name = params[:name]
        operation = params[:operation]

        return error("Name should be same as the policy name", :bad_request) if name && operation != :replace && policy[:name] != name

        policy_hash = policy_configuration.policy_hash.dup || {}

        case operation
        when :append then append_to_policy_hash(policy_hash, policy, type)
        when :replace then replace_in_policy_hash(policy_hash, name, policy, type)
        when :remove then remove_from_policy_hash(policy_hash, policy, type)
        end

        return error('Invalid policy YAML', :bad_request, pass_back: { details: policy_configuration_validation_errors(policy_hash) }) unless policy_configuration_valid?(policy_hash)

        success(policy_hash: policy_hash)
      rescue Error => e
        error(e.message)
      end

      private

      delegate :policy_configuration_validation_errors, :policy_configuration_valid?, to: :policy_configuration

      def append_to_policy_hash(policy_hash, policy, type)
        if policy_hash[type].blank?
          policy_hash[type] = [policy]
          return
        end

        raise Error, "Policy already exists with same name" if policy_exists?(policy_hash, policy[:name], type)

        policy_hash[type] += [policy]
      end

      def replace_in_policy_hash(policy_hash, name, policy, type)
        raise Error, "Policy already exists with same name" if name && name != policy[:name] && policy_exists?(policy_hash, policy[:name], type)

        existing_policy_index = check_if_policy_exists!(policy_hash, name || policy[:name], type)
        policy_hash[type][existing_policy_index] = policy
      end

      def remove_from_policy_hash(policy_hash, policy, type)
        check_if_policy_exists!(policy_hash, policy[:name], type)
        policy_hash[type].reject! { |p| p[:name] == policy[:name] }
      end

      def check_if_policy_exists!(policy_hash, policy_name, type)
        existing_policy_index = policy_exists?(policy_hash, policy_name, type)
        raise Error, "Policy does not exist" if existing_policy_index.nil?

        existing_policy_index
      end

      def policy_exists?(policy_hash, policy_name, type)
        policy_hash[type].find_index { |p| p[:name] == policy_name }
      end

      attr_reader :policy_configuration, :params
    end
  end
end
