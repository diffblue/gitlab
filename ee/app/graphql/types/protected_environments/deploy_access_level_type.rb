# frozen_string_literal: true

module Types
  module ProtectedEnvironments
    # This type is authorized in the parent entity.
    # rubocop:disable Graphql/AuthorizeTypes
    class DeployAccessLevelType < AuthorizableType
      graphql_name 'ProtectedEnvironmentDeployAccessLevel'
      description 'Which group, user or role is allowed to execute deployments to the environment.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
