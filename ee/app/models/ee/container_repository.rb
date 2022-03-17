# frozen_string_literal: true

module EE
  module ContainerRepository
    extend ActiveSupport::Concern

    GITLAB_ORG_NAMESPACE = 'gitlab-org'

    prepended do
      scope :project_id_in, ->(ids) { joins(:project).merge(::Project.id_in(ids)) }
    end

    class_methods do
      extend ::Gitlab::Utils::Override

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

        if ::ContainerRegistry::Migration.limit_gitlab_org?
          joins(project: [:namespace]).where(namespaces: { path: GITLAB_ORG_NAMESPACE })
        else
          joins(
            %{
              INNER JOIN "projects" on "projects"."id" = "container_repositories"."project_id"
              INNER JOIN "namespaces" on "namespaces"."id" = "projects"."namespace_id"
              INNER JOIN "gitlab_subscriptions" on "gitlab_subscriptions"."namespace_id" = "namespaces"."traversal_ids"[1]
              INNER JOIN "plans" on "plans"."id" = "gitlab_subscriptions"."hosted_plan_id"
            }
          ).where(plans: { id: ::ContainerRegistry::Migration.target_plan.id })
        end
      end
    end

    def push_blob(digest, file_path)
      client.push_blob(path, digest, file_path)
    end

    def push_manifest(tag, manifest, manifest_type)
      client.push_manifest(path, tag, manifest, manifest_type)
    end

    def blob_exists?(digest)
      client.blob_exists?(path, digest)
    end
  end
end
