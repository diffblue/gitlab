# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class PolicyCommitService < ::BaseContainerService
      def execute
        @policy_configuration = container.security_orchestration_policy_configuration

        return error('Security Policy Project does not exist') unless policy_configuration.present?

        validation_result = validate_policy_yaml
        return validation_result if validation_result[:status] != :success

        process_policy_result = process_policy
        return process_policy_result if process_policy_result[:status] != :success

        result = commit_policy(process_policy_result[:policy_hash])
        return error(result[:message], :bad_request) if result[:status] != :success

        success({ branch: branch_name })
      rescue StandardError => e
        error(e.message, :bad_request)
      end

      private

      def validate_policy_yaml
        params = {
          policy: policy,
          validate_approvals_required: validate_approvals_required?
        }

        Security::SecurityOrchestrationPolicies::ValidatePolicyService
          .new(container: container, current_user: current_user, params: params)
          .execute
      end

      def validate_approvals_required?
        params[:operation] != :remove
      end

      def process_policy
        ProcessPolicyService.new(
          policy_configuration: policy_configuration,
          params: {
            operation: params[:operation],
            name: params[:name],
            policy: policy,
            type: policy.delete(:type)&.to_sym
          }
        ).execute
      end

      def commit_policy(policy_hash)
        policy_yaml = YAML.dump(policy_hash.deep_stringify_keys)

        return create_commit(::Files::UpdateService, policy_yaml) if policy_configuration.policy_configuration_exists?

        create_commit(::Files::CreateService, policy_yaml)
      end

      def create_commit(service, policy_yaml)
        service.new(policy_configuration.security_policy_management_project, current_user, policy_commit_attrs(policy_yaml)).execute
      end

      def policy_commit_attrs(policy_yaml)
        {
          commit_message: commit_message,
          file_path: Security::OrchestrationPolicyConfiguration::POLICY_PATH,
          file_content: policy_yaml,
          branch_name: branch_name,
          start_branch: policy_configuration.default_branch_or_main
        }
      end

      def commit_message
        operation = case params[:operation]
                    when :append then 'Add a new policy to'
                    when :replace then 'Update policy in'
                    when :remove then 'Delete policy in'
                    end

        "#{operation} #{Security::OrchestrationPolicyConfiguration::POLICY_PATH}"
      end

      def branch_name
        @branch_name ||= params[:branch_name] || "update-policy-#{Time.now.to_i}"
      end

      def policy
        @policy ||= Gitlab::Config::Loader::Yaml.new(params[:policy_yaml]).load!
      end

      attr_reader :policy_configuration
    end
  end
end
