# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class NetworkPolicyType < BaseObject
    graphql_name 'NetworkPolicy'
    description 'Represents the network policy'

    field :name,
          GraphQL::Types::String,
          null: false,
          description: 'Name of the policy.'

    field :kind,
          NetworkPolicyKindEnum,
          null: false,
          description: 'Kind of the policy.'

    field :namespace,
          GraphQL::Types::String,
          null: false,
          description: 'Namespace of the policy.'

    field :enabled,
          GraphQL::Types::Boolean,
          null: false,
          description: 'Indicates whether this policy is enabled.'

    field :from_auto_devops,
          GraphQL::Types::Boolean,
          null: false,
          description: 'Indicates whether this policy is created from AutoDevops.'

    field :yaml,
          GraphQL::Types::String,
          null: false,
          description: 'YAML definition of the policy.'

    field :updated_at,
          Types::TimeType,
          null: false,
          description: 'Timestamp of when the policy YAML was last updated.'

    field :environments,
          Types::EnvironmentType.connection_type,
          null: true,
          description: 'Environments where this policy is applied.'

    def environments
      BatchLoader::GraphQL.for(object[:environment_ids]).batch do |policy_environment_ids, loader|
        finder = ::Environments::EnvironmentsFinder.new(object[:project], context[:current_user], environment_ids: policy_environment_ids.flatten.uniq)
        environments_by_id = finder.execute.index_by(&:id)

        policy_environment_ids.each do |ids|
          loader.call(ids, environments_by_id.values_at(*ids))
        end
      end
    end
  end
end
