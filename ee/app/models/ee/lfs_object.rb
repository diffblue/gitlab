# frozen_string_literal: true

module EE
  # LFS Object EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `LfsObject` model
  module LfsObject
    extend ActiveSupport::Concern

    STORE_COLUMN = :file_store

    prepended do
      include ::Gitlab::Geo::ReplicableModel

      with_replicator ::Geo::LfsObjectReplicator

      scope :project_id_in, ->(ids) { joins(:projects).merge(::Project.id_in(ids)) }
    end

    class_methods do
      # @param primary_key_in [Range, LfsObject] arg to pass to primary_key_in scope
      # @return [ActiveRecord::Relation<LfsObject>] everything that should be synced to this node, restricted by primary key
      def replicables_for_current_secondary(primary_key_in)
        node = ::Gitlab::Geo.current_node
        node.lfs_objects(primary_key_in: primary_key_in)
          .merge(object_storage_scope(node))
      end

      private

      def object_storage_scope(node)
        return all if node.sync_object_storage?

        with_files_stored_locally
      end
    end

    def log_geo_deleted_event
      # Keep empty for now. Should be addressed in future
      # by https://gitlab.com/gitlab-org/gitlab/-/issues/232917
    end
  end
end
