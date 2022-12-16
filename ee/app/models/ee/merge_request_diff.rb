# frozen_string_literal: true

module EE
  module MergeRequestDiff
    extend ActiveSupport::Concern

    prepended do
      include ::Geo::ReplicableModel
      include ObjectStorable
      include ::Geo::VerifiableModel

      delegate(*::Geo::VerificationState::VERIFICATION_METHODS, to: :merge_request_diff_detail)

      STORE_COLUMN = :external_diff_store

      with_replicator ::Geo::MergeRequestDiffReplicator

      has_one :merge_request_diff_detail, autosave: false, inverse_of: :merge_request_diff

      after_save :save_verification_details

      scope :has_external_diffs, -> { with_files.where(stored_externally: true) }
      scope :project_id_in, ->(ids) { where(merge_request_id: ::MergeRequest.where(target_project_id: ids)) }
      scope :available_replicables, -> { has_external_diffs }
      scope :available_verifiables, -> { joins(:merge_request_diff_detail) }
      scope :with_verification_state, ->(state) { joins(:merge_request_diff_detail).where(merge_request_diff_details: { verification_state: verification_state_value(state) }) }
      scope :checksummed, -> { joins(:merge_request_diff_detail).where.not(merge_request_diff_details: { verification_checksum: nil }) }
      scope :not_checksummed, -> { joins(:merge_request_diff_detail).where(merge_request_diff_details: { verification_checksum: nil }) }

      def verification_state_object
        merge_request_diff_detail
      end
    end

    class_methods do
      extend ::Gitlab::Utils::Override

      # Search for a list of merge_request_diffs based on the query given in `query`.
      #
      # @param [String] query term that will search over external_diff attribute
      #
      # @return [ActiveRecord::Relation<MergeRequestDiff>] a collection of merge request diffs
      def search(query)
        return all if query.empty?

        where(sanitize_sql_for_conditions({ external_diff: query })).limit(1000)
      end

      # @param primary_key_in [Range, MergeRequestDiff] arg to pass to primary_key_in scope
      # @return [ActiveRecord::Relation<MergeRequestDiff>] everything that should be synced to this node, restricted by primary key
      def replicables_for_current_secondary(primary_key_in)
        node = ::Gitlab::Geo.current_node

        available_replicables.primary_key_in(primary_key_in)
                             .merge(selective_sync_scope(node))
                             .merge(object_storage_scope(node))
      end

      override :verification_state_table_class
      def verification_state_table_class
        MergeRequestDiffDetail
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

    def merge_request_diff_detail
      super || build_merge_request_diff_detail
    end

    def log_geo_deleted_event
      # Keep empty for now. Should be addressed in future
      # by https://gitlab.com/gitlab-org/gitlab/issues/33817
    end
  end
end
