# frozen_string_literal: true

module Mutations
  module SecurityPolicy
    class CommitScanExecutionPolicy < BaseMutation
      include FindsProject

      graphql_name 'ScanExecutionPolicyCommit'

      authorize :security_orchestration_policies

      argument :project_path, GraphQL::Types::ID,
               required: true,
               description: 'Full path of the project.'

      argument :policy_yaml, GraphQL::Types::String,
               required: true,
               description: 'YAML snippet of the policy.'

      argument :operation_mode,
               Types::MutationOperationModeEnum,
               required: true,
               description: 'Changes the operation mode.'

      field :branch,
            GraphQL::Types::String,
            null: true,
            description: 'Name of the branch to which the policy changes are committed.'

      def resolve(args)
        project = authorized_find!(args[:project_path])
        raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'Feature disabled' unless allowed?(project)

        result = commit_policy(project, args[:policy_yaml], args[:operation_mode])
        error_message = result[:status] == :error ? result[:message] : nil

        {
          branch: result[:branch],
          errors: [error_message].compact
        }
      end

      private

      def allowed?(project)
        Feature.enabled?(:security_orchestration_policies_configuration, project)
      end

      def commit_policy(project, policy_yaml, operation_mode)
        ::Security::SecurityOrchestrationPolicies::PolicyCommitService
          .new(project: project, current_user: current_user, params: { policy_yaml: policy_yaml, operation: Types::MutationOperationModeEnum.enum.key(operation_mode).to_sym })
          .execute
      end
    end
  end
end
