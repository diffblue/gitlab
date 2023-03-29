# frozen_string_literal: true

module Mutations
  module Deployments
    class DeploymentApprove < BaseMutation
      graphql_name 'ApproveDeployment'

      argument :id,
        Types::GlobalIDType[::Deployment],
        required: true,
        description: 'ID of the deployment.'

      argument :status,
        Types::Deployments::ApprovalStatusEnum,
        required: true,
        description: 'Status of the approval (either `APPROVED` or `REJECTED`).'

      argument :comment,
        GraphQL::Types::String,
        required: false,
        description: 'Comment to go with the approval.'

      argument :represented_as,
        GraphQL::Types::String,
        required: false,
        description: 'Name of the User/Group/Role to use for the approval, ' \
                     'when the user belongs to multiple approval rules.'

      field :deployment_approval,
        Types::Deployments::ApprovalType,
        null: false,
        description: 'DeploymentApproval after mutation.'

      authorize :read_deployment

      def resolve(id:, status:, **args)
        deployment = authorized_find!(id: id)

        result = ::Deployments::ApprovalService.new(deployment.project, current_user, args).execute(deployment, status)

        {
          deployment_approval: result[:approval],
          errors: Array.wrap(result[:message])
        }
      end
    end
  end
end
