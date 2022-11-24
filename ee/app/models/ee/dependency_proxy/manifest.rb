# frozen_string_literal: true

module EE
  module DependencyProxy
    module Manifest
      extend ActiveSupport::Concern

      prepended do
        include ::Geo::ReplicableModel
        include ::Geo::VerifiableModel

        delegate(*::Geo::VerificationState::VERIFICATION_METHODS, to: :dependency_proxy_manifest_state)

        with_replicator ::Geo::DependencyProxyManifestReplicator

        has_one :dependency_proxy_manifest_state,
          autosave: false,
          inverse_of: :dependency_proxy_manifest,
          class_name: 'Geo::DependencyProxyManifestState',
          foreign_key: :dependency_proxy_manifest_id

        after_save :save_verification_details

        scope :with_verification_state, ->(state) do
          joins(:dependency_proxy_manifest_state)
            .where(dependency_proxy_manifest_states: { verification_state: verification_state_value(state) })
        end
        scope :checksummed,
          -> do
            joins(:dependency_proxy_manifest_state)
              .where.not(dependency_proxy_manifest_states: { verification_checksum: nil } )
          end
        scope :not_checksummed,
          -> do
            joins(:dependency_proxy_manifest_state)
              .where(dependency_proxy_manifest_states: { verification_checksum: nil } )
          end

        scope :available_verifiables, -> { joins(:dependency_proxy_manifest_state) }

        scope :group_id_in, ->(ids) { joins(:group).merge(::Namespace.id_in(ids)) }

        def verification_state_object
          dependency_proxy_manifest_state
        end
      end

      class_methods do
        extend ::Gitlab::Utils::Override

        def replicables_for_current_secondary(primary_key_in)
          node = ::Gitlab::Geo.current_node

          primary_key_in(primary_key_in)
            .merge(selective_sync_scope(node))
            .merge(object_storage_scope(node))
        end

        override :verification_state_table_class
        def verification_state_table_class
          Geo::DependencyProxyManifestState
        end

        private

        def selective_sync_scope(node)
          return all unless node.selective_sync?

          case node.selective_sync_type
          when 'namespaces'
            group_id_in(node.namespace_ids)
          when 'shards'
            group_id_in(node.namespaces_for_group_owned_replicables.select(:id))
          end
        end

        def object_storage_scope(node)
          return all if node.sync_object_storage?

          with_files_stored_locally
        end
      end

      def log_geo_deleted_event
        # Keep empty for now. Should be addressed in future
        # by https://gitlab.com/gitlab-org/gitlab/-/issues/259694
      end

      def dependency_proxy_manifest_state
        super || build_dependency_proxy_manifest_state
      end
    end
  end
end
