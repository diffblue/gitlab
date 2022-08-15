# frozen_string_literal: true

module Types
  module Ci
    class NamespaceCiCdSettingType < BaseObject
      graphql_name 'NamespaceCiCdSetting'

      authorize :admin_namespace

      field :allow_stale_runner_pruning, GraphQL::Types::Boolean,
        null: true,
        method: :allow_stale_runner_pruning?,
        description: 'Indicates if stale runners directly belonging to this namespace should be periodically pruned.'
      field :namespace, Types::NamespaceType,
        null: true, description: 'Namespace the CI/CD settings belong to.'
    end
  end
end
