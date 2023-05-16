# frozen_string_literal: true

module Geo
  # This concern is included on VerifiableModel and on VerifiableRegistry to
  # manage their verification fields.

  module VerificationState
    extend ActiveSupport::Concern
    include ::ShaAttribute
    include Delay
    include EachBatch
    include Gitlab::Geo::LogHelpers

    VERIFICATION_STATE_VALUES = {
      verification_pending: 0,
      verification_started: 1,
      verification_succeeded: 2,
      verification_failed: 3,
      verification_disabled: 4
    }.freeze

    VERIFICATION_TIMEOUT = 8.hours
    VERIFICATION_METHODS = [:verification_retry_at, :verification_retry_at=,
                            :verified_at, :verified_at=, :verification_failed?,
                            :verification_checksum, :verification_checksum=,
                            :verification_failure, :verification_failure=,
                            :verification_retry_count, :verification_retry_count=,
                            :verification_state=, :verification_state,
                            :verification_started_at=, :verification_started_at,
                            :verification_started!, :verification_pending!,
                            :verification_succeeded!, :verification_failed!,
                            :verification_started?, :verification_succeeded,
                            :with_verification_state, :verification_started,
                            :verification_succeeded?, :verification_failed,
                            :verification_pending, :verification_disabled,
                            :verification_disabled!, :verification_disabled?].freeze

    included do
      sha_attribute :verification_checksum

      scope :verification_pending, -> { available_verifiables.with_verification_state(:verification_pending) }
      scope :verification_started, -> { available_verifiables.with_verification_state(:verification_started) }
      scope :verification_succeeded, -> { available_verifiables.with_verification_state(:verification_succeeded) }
      scope :verification_failed, -> { available_verifiables.with_verification_state(:verification_failed) }
      scope :verification_disabled, -> { available_verifiables.with_verification_state(:verification_disabled) }
      scope :verification_not_disabled, -> { available_verifiables.where.not(verification_state: verification_state_value(:verification_disabled)) }
      scope :checksummed, -> { where.not(verification_checksum: nil) }
      scope :not_checksummed, -> { where(verification_checksum: nil) }
      scope :verification_timed_out, -> { available_verifiables.where(verification_arel_table[:verification_state].eq(1)).where(verification_arel_table[:verification_started_at].lt(VERIFICATION_TIMEOUT.ago)) }
      scope :verification_retry_due, -> { where(verification_arel_table[:verification_retry_at].eq(nil).or(verification_arel_table[:verification_retry_at].lt(Time.current))) }
      scope :needs_verification, -> { available_verifiables.merge(with_verification_state(:verification_pending).or(with_verification_state(:verification_failed).verification_retry_due)) }
      scope :needs_reverification, -> { verification_succeeded.where("verified_at < ?", ::Gitlab::Geo.current_node.minimum_reverification_interval.days.ago) }

      private_class_method :start_verification_batch
      private_class_method :start_verification_batch_query
      private_class_method :start_verification_batch_subselect
    end

    class_methods do
      include Delay

      def verification_state_value(state_string)
        VERIFICATION_STATE_VALUES[state_string]
      end

      # Returns IDs of records that are pending verification.
      #
      # Atomically marks those records "verification_started" in the same DB
      # query.
      #
      def verification_pending_batch(batch_size:)
        relation = verification_pending.order(verification_arel_table[:verified_at].asc.nulls_first).limit(batch_size)

        start_verification_batch(relation)
      end

      # Returns IDs of records that failed to verify (calculate and save checksum).
      #
      # Atomically marks those records "verification_started" in the same DB
      # query.
      #
      def verification_failed_batch(batch_size:)
        relation = verification_failed.verification_retry_due.order(verification_arel_table[:verification_retry_at].asc.nulls_first).limit(batch_size)

        start_verification_batch(relation)
      end

      # @return [Integer] number of records that need verification
      def needs_verification_count(limit:)
        needs_verification.limit(limit).count
      end

      # @return [Integer] number of records that need reverification
      def needs_reverification_count(limit:)
        needs_reverification.limit(limit).count
      end

      # Atomically marks the records as verification_started, with a
      # verification_started_at time, and returns the primary key of each
      # updated row. This allows VerificationBatchWorker to concurrently get
      # unique batches of primary keys to process.
      #
      # @param [ActiveRecord::Relation] relation with appropriate where, order, and limit defined
      # @return [Array<Integer>] primary key of each updated row
      def start_verification_batch(relation)
        query = start_verification_batch_query(relation)

        # This query performs a write, so we need to wrap it in a transaction
        # to stick to the primary database.
        self.transaction do
          self.connection.execute(query).to_a.map do |row|
            row[self.verification_state_model_key.to_s]
          end
        end
      end

      # Returns a SQL statement which would update all the rows in the
      # relation as verification_started, with a verification_started_at time,
      # and returns the primary key of each updated row.
      #
      # @param [ActiveRecord::Relation] relation with appropriate where, order, and limit defined
      # @return [String] SQL statement which would update all and return primary key of each row
      def start_verification_batch_query(relation)
        started_enum_value = VERIFICATION_STATE_VALUES[:verification_started]

        <<~SQL.squish
          UPDATE #{verification_state_table_name}
          SET "verification_state" = #{started_enum_value},
            "verification_started_at" = NOW()
          WHERE #{self.verification_state_model_key} IN (#{start_verification_batch_subselect(relation).to_sql})

          RETURNING #{self.verification_state_model_key}
        SQL
      end

      # This query locks the rows during the transaction, and skips locked
      # rows so that this query can be run concurrently, safely and reasonably
      # efficiently.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/300051#note_496889565
      #
      # @param [ActiveRecord::Relation] relation with appropriate where, order, and limit defined
      # @return [String] SQL statement which selects the primary keys to update
      def start_verification_batch_subselect(relation)
        relation
          .select(self.verification_state_model_key)
          .lock('FOR UPDATE SKIP LOCKED')
      end

      # Override this method in the class that includes this concern to specify
      # a different ActiveRecord class to store verification state
      # See module EE::MergeRequestDiff for example
      def verification_state_table_class
        self
      end

      # Overridden in ReplicableRegistry
      def verification_state_model_key
        verification_state_table_class.primary_key
      end

      def verification_state_table_name
        verification_state_table_class.table_name
      end

      def verification_arel_table
        verification_state_table_class.arel_table
      end

      # @return whether primary checksum data is stored in a table separate
      #         from the model table
      def separate_verification_state_table?
        verification_state_table_name != table_name
      end

      def verification_timed_out_batch_query
        return verification_timed_out unless separate_verification_state_table?

        verification_state_table_class.where(self.verification_state_model_key => verification_timed_out)
      end

      # Fail verification for records which started verification a long time ago
      def fail_verification_timeouts
        attrs = {
          verification_state: verification_state_value(:verification_failed),
          verification_failure: "Verification timed out after #{VERIFICATION_TIMEOUT}",
          verification_checksum: nil,
          verification_retry_count: 1,
          verification_retry_at: next_retry_time(1),
          verified_at: Time.current
        }

        verification_timed_out_batch_query.each_batch do |relation|
          relation.update_all(attrs)
        end
      end

      # Reverifies batch and returns the number of records.
      #
      # Atomically marks those records "verification_pending" in the same DB
      # query.
      #
      def reverify_batch(batch_size:)
        relation = reverification_batch_relation(batch_size: batch_size)

        mark_as_verification_pending(relation)
      end

      # Returns IDs of records that need re-verification.
      #
      # Atomically marks those records "verification_pending" in the same DB
      # query.
      def reverification_batch_relation(batch_size:)
        needs_reverification.order(:verified_at).limit(batch_size)
      end

      # Atomically marks the records as verification_pending.
      # Returns the number of records set to be reverified.
      #
      # @param [ActiveRecord::Relation] relation with appropriate where, order, and limit defined
      # @return [Integer] number of records
      def mark_as_verification_pending(relation)
        query = mark_as_verification_pending_query(relation)

        self.connection.execute(query).cmd_tuples
      end

      # Returns a SQL statement which would update all the rows in the
      # relation as verification_pending
      # and returns the number of updated rows.
      #
      # @param [ActiveRecord::Relation] relation with appropriate where, order, and limit defined
      # @return [String] SQL statement which would update all and return the number of rows
      def mark_as_verification_pending_query(relation)
        pending_enum_value = VERIFICATION_STATE_VALUES[:verification_pending]

        <<~SQL.squish
          UPDATE #{verification_state_table_name}
          SET "verification_state" = #{pending_enum_value}
          WHERE #{self.verification_state_model_key} IN (#{relation.select(self.verification_state_model_key).to_sql})
        SQL
      end
    end

    # Provides a safe and easy way to manage the verification state for a
    # synchronous checksum calculation.
    #
    # @yieldreturn [String] calculated checksum value
    def track_checksum_attempt!(&block)
      # This line only applies to Geo::VerificationWorker, not
      # Geo::VerificationBatchWorker, since the latter sets the whole batch to
      # "verification_started" in the same DB query that fetches the batch.
      verification_started! unless verification_started?

      calculation_started_at = Time.current

      checksum = yield

      track_checksum_result!(checksum, calculation_started_at)
    rescue StandardError => e
      # Reset any potential changes from track_checksum_result, i.e.
      # verification_retry_count may have been cleared.
      reset

      verification_failed_with_message!('Error during verification', e)
    end

    # Convenience method to update checksum and transition to success state.
    #
    # @param [String] checksum value generated by the checksum routine
    # @param [DateTime] calculation_started_at the moment just before the
    #                   checksum routine was called
    def verification_succeeded_with_checksum!(checksum, calculation_started_at)
      self.verification_checksum = checksum
      self.verification_succeeded!

      if resource_updated_during_checksum?(calculation_started_at)
        # just let backfill pick it up
        self.verification_pending!
      end

      return unless Gitlab::Geo.primary?

      self.replicator.handle_after_checksum_succeeded
    end

    # Convenience method to update failure message and transition to failed
    # state.
    #
    # @param [String] message error information
    # @param [StandardError] error exception
    def verification_failed_with_message!(message, error = nil)
      log_error(message, error)

      self.verification_failure = message
      self.verification_failure += ": #{error.message}" if error.respond_to?(:message)
      self.verification_failure.truncate(255)
      self.verification_checksum = nil

      self.verification_failed!
    end

    private

    # Records the calculated checksum result
    #
    # Overridden by ReplicableRegistry so it can also compare with primary
    # checksum.
    #
    # @param [String] calculated checksum value
    # @param [Time] when checksum calculation was started
    def track_checksum_result!(checksum, calculation_started_at)
      verification_succeeded_with_checksum!(checksum, calculation_started_at)
    end

    def resource_updated_during_checksum?(calculation_started_at)
      self.reset.verification_started_at > calculation_started_at
    end
  end
end
