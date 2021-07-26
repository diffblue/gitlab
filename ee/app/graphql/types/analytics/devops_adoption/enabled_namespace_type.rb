# frozen_string_literal: true
# rubocop:disable Graphql/AuthorizeTypes

module Types
  module Analytics
    module DevopsAdoption
      class EnabledNamespaceType < BaseObject
        graphql_name 'DevopsAdoptionEnabledNamespace'
        description 'Enabled namespace for DevopsAdoption'

        field :id, GraphQL::Types::ID, null: false,
              description: "ID of the enabled namespace."

        field :namespace, Types::NamespaceType, null: true,
              description: 'Namespace which should be calculated.'

        field :display_namespace, Types::NamespaceType, null: true,
              description: 'Namespace where data should be displayed.'

        field :snapshots,
              description: 'Data snapshots of the namespace.',
              resolver: Resolvers::Analytics::DevopsAdoption::SnapshotsResolver

        field :latest_snapshot, SnapshotType, null: true,
              description: 'Metrics snapshot for previous month for the enabled namespace.'

        def latest_snapshot
          BatchLoader::GraphQL.for(object.namespace_id).batch(key: :devops_adoption_latest_snapshots) do |ids, loader, _args|
            snapshots = ::Analytics::DevopsAdoption::Snapshot.latest_for_namespace_ids(ids).index_by(&:namespace_id)

            ids.each do |id|
              loader.call(id, snapshots[id])
            end
          end
        end
      end
    end
  end
end
