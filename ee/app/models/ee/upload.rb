# frozen_string_literal: true

module EE
  # Upload EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Upload` model
  module Upload
    extend ActiveSupport::Concern

    prepended do
      include ::Gitlab::SQL::Pattern
      include ::Gitlab::Geo::ReplicableModel

      with_replicator ::Geo::UploadReplicator

      scope :for_model, ->(model) { where(model_id: model.id, model_type: model.class.name) }
      scope :syncable, -> { with_files_stored_locally }
    end

    class_methods do
      # @param primary_key_in [Range, Upload] arg to pass to primary_key_in scope
      # @return [ActiveRecord::Relation<Upload>] everything that should be synced to this node, restricted by primary key
      def replicables_for_current_secondary(primary_key_in)
        node = ::Gitlab::Geo.current_node

        primary_key_in(primary_key_in)
          .merge(selective_sync_scope(node))
          .merge(object_storage_scope(node))
      end

      # Searches for a list of uploads based on the query given in `query`.
      #
      # On PostgreSQL this method uses "ILIKE" to perform a case-insensitive
      # search.
      #
      # query - The search query as a String.
      def search(query)
        fuzzy_search(query, [:path])
      end

      private

      # @return [ActiveRecord::Relation<Upload>] scope observing object storage settings of the given node
      def object_storage_scope(node)
        return all if node.sync_object_storage?

        with_files_stored_locally
      end

      # @return [ActiveRecord::Relation<Upload>] scope observing selective sync settings of the given node
      def selective_sync_scope(node)
        if node.selective_sync?
          group_attachments(node).or(project_attachments(node)).or(other_attachments)
        else
          all
        end
      end

      # @return [ActiveRecord::Relation<Upload>] scope of Namespace-associated uploads observing selective sync settings of the given node
      def group_attachments(node)
        where(model_type: 'Namespace', model_id: node.namespaces_for_group_owned_replicables.select(:id))
      end

      # @return [ActiveRecord::Relation<Upload>] scope of Project-associated uploads observing selective sync settings of the given node
      def project_attachments(node)
        where(model_type: 'Project', model_id: node.projects.select(:id))
      end

      # @return [ActiveRecord::Relation<Upload>] scope of uploads which are not associated with Namespace or Project
      def other_attachments
        where.not(model_type: %w[Namespace Project])
      end
    end

    def log_geo_deleted_event
      # Keep empty for now. Should be addressed in future
      # by https://gitlab.com/gitlab-org/gitlab/issues/33817
    end
  end
end
