# frozen_string_literal: true

module Geo
  module ReplicableModel
    extend ActiveSupport::Concern
    include Checksummable

    included do
      # If this hook turns out not to apply to all Models, perhaps we should extract a `ReplicableBlobModel`
      after_create_commit -> { replicator.handle_after_create_commit if replicator.respond_to?(:handle_after_create_commit) }
      after_destroy -> { replicator.handle_after_destroy if replicator.respond_to?(:handle_after_destroy) }

      # Temporarily defining `verification_succeeded` and
      # `verification_failed` for unverified models while verification is
      # under development to avoid breaking GeoNodeStatusCheck code.
      # TODO: Remove these after including `::Geo::VerificationState` on
      # all models. https://gitlab.com/gitlab-org/gitlab/-/issues/280768
      scope :verification_succeeded, -> { none }
      scope :verification_failed, -> { none }

      # These scopes are intended to be overridden as needed
      scope :available_replicables, -> { all }

      # On primary, `verifiables` are records that can be checksummed and/or are replicable.

      # On secondary, `verifiables` are records that have already been replicated
      # and (ideally) have been checksummed on the primary

      scope :verifiables, -> { self.respond_to?(:with_files_stored_locally) ? available_replicables.with_files_stored_locally : available_replicables }

      # When storing verification details in the same table as the model,
      # the scope `available_verifiables` returns only those records
      # that are eligible for verification, i.e. the same as the scope
      # `verifiables`.

      # When using a separate table to store verification details,
      # the scope `available_verifiables` should return all records
      # from the separate table because the separate table will
      # always only have records corresponding to replicables that are verifiable.
      # For this, override the scope in the replicable model, e.g. like so in
      # `MergeRequestDiff`,
      # `scope :available_verifiables, -> { joins(:merge_request_diff_detail) }`

      scope :available_verifiables, -> { verifiables }
    end

    class_methods do
      # Associate current model with specified replicator
      #
      # @param [Gitlab::Geo::Replicator] klass
      def with_replicator(klass)
        raise ArgumentError, 'Must be a class inheriting from Gitlab::Geo::Replicator' unless klass < ::Gitlab::Geo::Replicator

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          define_method :replicator do
            @_replicator ||= klass.new(model_record: self)
          end

          define_singleton_method :replicator_class do
            @_replicator_class ||= klass
          end
        RUBY
      end
    end

    # Geo Replicator
    #
    # @abstract
    # @return [Gitlab::Geo::Replicator]
    def replicator
      raise NotImplementedError, 'There is no Replicator defined for this model'
    end

    def in_replicables_for_current_secondary?
      self.class.replicables_for_current_secondary(self).exists?
    end
  end
end
