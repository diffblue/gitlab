# frozen_string_literal: true

module Types
  class DeploymentType < BaseObject
    graphql_name 'Deployment'
    description 'The deployment of an environment'

    present_using Deployments::DeploymentPresenter

    authorize :read_deployment

    field :id,
      GraphQL::Types::ID,
      description: 'Global ID of the deployment.'

    field :iid,
      GraphQL::Types::ID,
      description: 'Project-level internal ID of the deployment.'

    field :ref,
      GraphQL::Types::String,
      description: 'Git-Ref that the deployment ran on.'

    field :tag,
      GraphQL::Types::Boolean,
      description: 'True or false if the deployment ran on a Git-tag.'

    field :sha,
      GraphQL::Types::String,
      description: 'Git-SHA that the deployment ran on.'

    field :created_at,
      Types::TimeType,
      description: 'When the deployment record was created.'

    field :updated_at,
      Types::TimeType,
      description: 'When the deployment record was updated.'

    field :finished_at,
      Types::TimeType,
      description: 'When the deployment finished.'

    field :status,
      Types::DeploymentStatusEnum,
      description: 'Status of the deployment.'
  end
end
