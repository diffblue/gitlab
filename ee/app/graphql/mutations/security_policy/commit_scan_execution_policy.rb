# frozen_string_literal: true

module Mutations
  module SecurityPolicy
    class CommitScanExecutionPolicy < BaseMutation
      graphql_name 'ScanExecutionPolicyCommit'
      description 'Commits the `policy_yaml` content to the assigned security policy project for the given project(`project_path`)'

      include FindsProject

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

      argument :name, GraphQL::Types::String,
               required: false,
               description: 'Name of the policy. If the name is null, the `name` field from `policy_yaml` is used.'

      field :branch,
            GraphQL::Types::String,
            null: true,
            description: 'Name of the branch to which the policy changes are committed.'

      def resolve(args)
        project = authorized_find!(args[:project_path])

        result = commit_policy(project, args)
        error_message = result[:status] == :error ? result[:message] : nil
        error_details = result[:status] == :error ? result[:details] : nil

        {
          branch: result[:branch],
          errors: [error_message, *error_details].compact
        }
      end

      private

      def commit_policy(project, args)
        ::Security::SecurityOrchestrationPolicies::PolicyCommitService
          .new(project: project, current_user: current_user, params: {
            name: args[:name],
            policy_yaml: args[:policy_yaml],
            operation: Types::MutationOperationModeEnum.enum.key(args[:operation_mode]).to_sym
          })
          .execute
      end
    end
  end
end
