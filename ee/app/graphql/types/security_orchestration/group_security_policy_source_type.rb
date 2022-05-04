# frozen_string_literal: true

module Types
  module SecurityOrchestration
    # rubocop: disable Graphql/AuthorizeTypes
    # this represents a hash, from the orchestration policy configuration
    # the authorization happens for that configuration
    class GroupSecurityPolicySourceType < BaseObject
      graphql_name 'GroupSecurityPolicySource'
      description 'Represents the source of a security policy belonging to a group'

      field :inherited, GraphQL::Types::Boolean,
            null: false,
            description: 'Indicates whether this policy is inherited from parent group.'

      field :namespace, Types::NamespaceType,
            null: true,
            description: 'Project the policy is associated with.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
