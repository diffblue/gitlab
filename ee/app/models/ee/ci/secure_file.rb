# frozen_string_literal: true

module EE
  # CI::SecureFile EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Ci::SecureFile` model
  module Ci
    module SecureFile
      extend ActiveSupport::Concern

      EE_SEARCHABLE_ATTRIBUTES = %i[name].freeze

      prepended do
        include ::Geo::ReplicableModel
        include ::Geo::VerifiableModel
        include ::Gitlab::SQL::Pattern
        include Artifactable

        delegate(*::Geo::VerificationState::VERIFICATION_METHODS, to: :ci_secure_file_state)

        with_replicator ::Geo::CiSecureFileReplicator

        has_one :ci_secure_file_state, autosave: false, inverse_of: :ci_secure_file,
                                       class_name: 'Geo::CiSecureFileState', foreign_key: :ci_secure_file_id

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
        scope :with_files_stored_locally, -> { where(file_store: ::ObjectStorage::Store::LOCAL) }

        def verification_state_object
          ci_secure_file_state
        end
      end

      class_methods do
        extend ::Gitlab::Utils::Override

        # Search for a list of ci_secure_files based on the query given in `query`.
        #
        # @param [String] query term that will search over secure_file :name attribute
        #
        # @return [ActiveRecord::Relation<Ci::SecureFile>] a collection of secure files
        def search(query)
          return all if query.empty?

          fuzzy_search(query, EE_SEARCHABLE_ATTRIBUTES)
        end

        override :verification_state_table_class
        def verification_state_table_class
          ::Geo::CiSecureFileState
        end
      end

      def ci_secure_file_state
        super || build_ci_secure_file_state
      end
    end
  end
end
