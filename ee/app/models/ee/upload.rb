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
      include ::Geo::ReplicableModel
      include ::Geo::VerifiableModel

      with_replicator ::Geo::UploadReplicator

      scope :for_model, ->(model) { where(model_id: model.id, model_type: model.class.name) }
      scope :syncable, -> { with_files_stored_locally }
      scope :with_verification_state, ->(state) { joins(:upload_state).where(upload_states: { verification_state: verification_state_value(state) }) }
      scope :checksummed, -> { joins(:upload_state).where.not(upload_states: { verification_checksum: nil } ) }
      scope :not_checksummed, -> { joins(:upload_state).where(upload_states: { verification_checksum: nil } ) }

      scope :available_verifiables, -> { joins(:upload_state) }

      has_one :upload_state,
              autosave: false,
              inverse_of: :upload,
              class_name: '::Geo::UploadState'

      delegate :verification_retry_at, :verification_retry_at=,
               :verified_at, :verified_at=,
               :verification_checksum, :verification_checksum=,
               :verification_failure, :verification_failure=,
               :verification_retry_count, :verification_retry_count=,
               :verification_state=, :verification_state,
               :verification_started_at=, :verification_started_at,
               to: :upload_state

      after_save :save_verification_details

      def verification_state_object
        upload_state
      end
    end

    class_methods do
      extend ::Gitlab::Utils::Override

      override :verification_state_table_class
      def verification_state_table_class
        ::Geo::UploadState
      end

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

    def upload_state
      super || build_upload_state
    end
  end
end
