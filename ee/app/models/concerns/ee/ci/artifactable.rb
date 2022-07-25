# frozen_string_literal: true

module EE
  module Ci
    module Artifactable
      extend ActiveSupport::Concern

      class_methods do
        # @param primary_key_in [Range, Ci::{PipelineArtifact|JobArtifact|SecureFile}] arg to pass to primary_key_in scope
        # @return [ActiveRecord::Relation<Ci::{PipelineArtifact|JobArtifact|SecureFile}>] everything that should be synced to this node, restricted by primary key
        def replicables_for_current_secondary(primary_key_in)
          node = ::Gitlab::Geo.current_node

          replicables =
            primary_key_in(primary_key_in)
              .merge(object_storage_scope(node))

          selective_sync_scope(node, replicables)
        end

        # @return [ActiveRecord::Relation<Ci::{PipelineArtifact|JobArtifact|SecureFile}>] observing object storage settings of the given node
        def object_storage_scope(node)
          return all if node.sync_object_storage?

          with_files_stored_locally
        end

        # The primary_key_in in replicables_for_current_secondary method is at most a range of IDs with a maximum of 10_000 records
        # between them. We can additionally reduce the batch size to 1_000 just for pipeline artifacts and job artifacts if needed.
        #
        # @return [ActiveRecord::Relation<Ci::{PipelineArtifact|JobArtifact|SecureFile}>] observing selective sync settings of the given node
        def selective_sync_scope(node, replicables)
          return replicables unless node.selective_sync?

          # Note that we can't do node.projects.ids since it can have millions of records.
          replicables_project_ids = replicables.distinct.pluck(:project_id)
          selective_projects_ids  = node.projects.id_in(replicables_project_ids).pluck_primary_key

          replicables.project_id_in(selective_projects_ids)
        end
      end
    end
  end
end
