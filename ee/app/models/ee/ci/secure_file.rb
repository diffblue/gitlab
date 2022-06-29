# frozen_string_literal: true

module EE
  # CI::SecureFile EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Ci::SecureFile` model
  module Ci
    module SecureFile
      extend ActiveSupport::Concern

      prepended do
        include ::Geo::ReplicableModel
        include ::Geo::VerifiableModel

        delegate(*::Geo::VerificationState::VERIFICATION_METHODS, to: :ci_secure_file_state)

        with_replicator Geo::CiSecureFileReplicator

        has_one :ci_secure_file_state, autosave: false, inverse_of: :ci_secure_file,
          class_name: 'Geo::SecureFileState', foreign_key: :ci_secure_file_id

        after_save :save_verification_details

        scope :with_verification_state, ->(state) {
                                          joins(:ci_secure_file_state).where(
                                            ci_secure_file_states: {
                                              verification_state: verification_state_value(state)
                                            }
                                          )
                                        }
        scope :checksummed, -> {
                              joins(:ci_secure_file_state).where.not(
                                ci_secure_file_states: { verification_checksum: nil }
                              )
                            }
        scope :not_checksummed, -> {
                                  joins(:ci_secure_file_state).where(
                                    ci_secure_file_states: { verification_checksum: nil }
                                  )
                                }

        scope :available_verifiables, -> { joins(:ci_secure_file_state) }

        def verification_state_object
          ci_secure_file_state
        end
      end

      class_methods do
        extend ::Gitlab::Utils::Override

        # @param primary_key_in [Range, CiSecureFile] arg to pass to primary_key_in scope
        # @return [ActiveRecord::Relation<CiSecureFile>] everything that should be synced
        # to this node, restricted by primary key
        def replicables_for_current_secondary(primary_key_in)
          # This issue template does not help you write this method.
          #
          # This method is called only on Geo secondary sites. It is called when
          # we want to know which records to replicate. This is not easy to automate
          # because for example:
          #
          # * The "selective sync" feature allows admins to choose which namespaces
          #   to replicate, per secondary site. Most Models are scoped to a
          #   namespace, but the nature of the relationship to a namespace varies
          #   between Models.
          # * The "selective sync" feature allows admins to choose which shards to
          #   replicate, per secondary site. Repositories are associated with
          #   shards. Most blob types are not, but Project Uploads are.
          # * Remote stored replicables are not replicated, by default. But the
          #   setting `sync_object_storage` enables replication of remote stored
          #   replicables.
          #
          # Search the codebase for examples, and consult a Geo expert if needed.
        end

        override :verification_state_table_class
        def verification_state_table_class
          ::Geo::SecureFileState
        end
      end

      def ci_secure_file_state
        super || build_ci_secure_file_state
      end
    end
  end
end
