# frozen_string_literal: true

module EE
  module PagesDeployment
    extend ActiveSupport::Concern

    prepended do
      include ::Gitlab::Geo::ReplicableModel

      with_replicator Geo::PagesDeploymentReplicator
    end

    class_methods do
      def replicables_for_current_secondary(primary_key_in)
        node = ::Gitlab::Geo.current_node

        primary_key_in(primary_key_in)
          .merge(selective_sync_scope(node))
          .merge(object_storage_scope(node))
      end

      private

      def object_storage_scope(node)
        return all if node.sync_object_storage?

        with_files_stored_locally
      end

      def selective_sync_scope(node)
        return all unless node.selective_sync?

        project_id_in(node.projects)
      end
    end

    def log_geo_deleted_event
      # Keep empty for now. Should be addressed in future
      # by https://gitlab.com/gitlab-org/gitlab/-/issues/232917
    end
  end
end
