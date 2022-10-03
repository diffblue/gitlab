# frozen_string_literal: true

module Geo
  module ReplicableModel
    extend ActiveSupport::Concern
    include Checksummable
    include HasReplicator
    include ::Gitlab::Geo::LogHelpers

    included do
      # If this hook turns out not to apply to all Models, perhaps we should extract a `ReplicableBlobModel`
      after_create_commit :geo_create_event!
      after_destroy -> do
        replicator.handle_after_destroy if replicator.respond_to?(:handle_after_destroy)
      rescue StandardError => err
        log_error("Geo replicator after_destroy failed", err)
      end

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

      # The method is tested but undercoverage task doesn't detect it.
      # :nocov:
      def geo_create_event!
        replicator.handle_after_create_commit if replicator.respond_to?(:handle_after_create_commit)
      rescue StandardError => err
        log_error("Geo replicator after_create_commit failed", err)
      end
      # :nocov:
    end

    def in_replicables_for_current_secondary?
      self.class.replicables_for_current_secondary(self).exists?
    end
  end
end
