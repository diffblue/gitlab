# frozen_string_literal: true

module Types
  module SecurityOrchestration
    # rubocop: disable Graphql/AuthorizeTypes
    # this represents a hash, from the orchestration policy configuration
    # the authorization happens for that configuration
    class ProjectSecurityPolicySourceType < BaseObject
      graphql_name 'ProjectSecurityPolicySource'
      description 'Represents the source of a security policy belonging to a project'

      field :project, Types::ProjectType, null: true, description: 'Project the policy is associated with.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
