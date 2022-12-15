# frozen_string_literal: true

module EE
  module ContainerRepository
    extend ActiveSupport::Concern

    GITLAB_ORG_NAMESPACE = 'gitlab-org'
    EE_SEARCHABLE_ATTRIBUTES = %i[name].freeze

    prepended do
      include ::Geo::ReplicableModel

      with_replicator ::Geo::ContainerRepositoryReplicator

      scope :project_id_in, ->(ids) { joins(:project).merge(::Project.id_in(ids)) }
    end

    class_methods do
      extend ::Gitlab::Utils::Override

      # Search for a list of container_repositories based on the query given in `query`.
      #
      # @param [String] query term that will search over container_repository :name attribute
      #
      # @return [ActiveRecord::Relation<ContainerRepository>] a collection of container repositories
      def search(query)
        return all if query.empty?

        fuzzy_search(query, EE_SEARCHABLE_ATTRIBUTES)
      end

      # @param primary_key_in [Range, ContainerRepository] arg to pass to primary_key_in scope
      # @return [ActiveRecord::Relation<ContainerRepository>] everything that should be synced to this node, restricted by primary key
      def replicables_for_current_secondary(primary_key_in)
        node = ::Gitlab::Geo.current_node

        node.container_repositories.primary_key_in(primary_key_in)
      end

      override :with_target_import_tier
      def with_target_import_tier
        # self-managed instances are singlular plans, so they do not need
        # these filters
        return all unless ::Gitlab.com?
        return all if ::ContainerRegistry::Migration.all_plans?

        if ::ContainerRegistry::Migration.limit_gitlab_org?
          gitlab_org_namespace = ::Namespace.top_most.by_path(GITLAB_ORG_NAMESPACE)
          return none unless gitlab_org_namespace

          project_scope = ::Project.for_group_and_its_subgroups(gitlab_org_namespace)
                            .select(:id)
          where(project_id: project_scope)
        else
          where(migration_plan: ::ContainerRegistry::Migration.target_plans)
        end
      end
    end

    def push_blob(digest, blob_io, size)
      client.push_blob(path, digest, blob_io, size)
    end

    def push_manifest(tag, manifest, manifest_type)
      client.push_manifest(path, tag, manifest, manifest_type)
    end

    def blob_exists?(digest)
      client.blob_exists?(path, digest)
    end
  end
end
