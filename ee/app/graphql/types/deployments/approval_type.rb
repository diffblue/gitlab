# frozen_string_literal: true

module Types
  module Deployments
    # This type is authorized in the parent entity.
    # rubocop:disable Graphql/AuthorizeTypes
    class ApprovalType < BaseObject
      graphql_name 'DeploymentApproval'
      description 'Approval of the deployment.'

      field :user,
            ::Types::UserType,
            description: 'User who approved or rejected the deployment.'

      field :status,
            Types::Deployments::ApprovalStatusEnum,
            description: 'Whether the deployment was approved/rejected.'

      field :created_at,
            Types::TimeType,
            description: 'When the user approved/rejected first time.'

      field :updated_at,
            Types::TimeType,
            description: 'When the user updated the approval.'

      field :comment,
            GraphQL::Types::String,
            description: 'Additional comment.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
