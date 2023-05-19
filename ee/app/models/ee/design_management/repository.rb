# frozen_string_literal: true

module EE
  module DesignManagement
    module Repository
      extend ActiveSupport::Concern

      prepended do
        include ::Geo::ReplicableModel
        include ::Geo::VerifiableModel

        delegate(*::Geo::VerificationState::VERIFICATION_METHODS, to: :design_management_repository_state)

        with_replicator Geo::DesignManagementRepositoryReplicator

        has_one :design_management_repository_state,
          autosave: false,
          inverse_of: :design_management_repository,
          class_name: 'Geo::DesignManagementRepositoryState',
          foreign_key: 'design_management_repository_id'

        after_save :save_verification_details

        scope :available_verifiables, -> { joins(:design_management_repository_state) }

        scope :checksummed, -> {
          joins(:design_management_repository_state)
            .where
              .not(design_management_repository_states: { verification_checksum: nil })
        }

        scope :not_checksummed, -> {
          joins(:design_management_repository_state)
            .where(design_management_repository_states: { verification_checksum: nil })
        }

        scope :with_verification_state, ->(state) {
          joins(:design_management_repository_state)
            .where(design_management_repository_states: { verification_state: verification_state_value(state) })
        }

        scope :project_id_in, ->(ids) { where(project_id: ids) }
      end

      def verification_state_object
        design_management_repository_state
      end

      class_methods do
        extend ::Gitlab::Utils::Override

        # @param primary_key_in [Range, DesignRepository] arg to pass to primary_key_in scope
        # @return [ActiveRecord::Relation<DesignRepository>] everything that should be synced
        # to this node, restricted by primary key
        def replicables_for_current_secondary(primary_key_in)
          node = ::Gitlab::Geo.current_node

          replicables = primary_key_in(primary_key_in)
          return replicables unless node.selective_sync?

          replicables_project_ids = replicables.distinct.pluck(:project_id)
          selective_projects_ids  = node.projects.id_in(replicables_project_ids).pluck_primary_key

          replicables.project_id_in(selective_projects_ids)
        end

        override :verification_state_table_class
        def verification_state_table_class
          Geo::DesignManagementRepositoryState
        end
      end

      # Geo checks this method in FrameworkRepositorySyncService to avoid
      # snapshotting repositories using object pools
      def pool_repository
        nil
      end

      def design_management_repository_state
        super || build_design_management_repository_state
      end
    end
  end
end
