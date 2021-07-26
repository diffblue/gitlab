# frozen_string_literal: true

module Gitlab
  module Geo
    # This concern is included on ActiveRecord classes to manage their
    # verification fields. This concern does not handle how verification is
    # performed.
    #
    # This is a separate concern from Gitlab::Geo::ReplicableModel because e.g.
    # MergeRequestDiff stores its verification state in a separate table with
    # the association to MergeRequestDiffDetail.
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
        verification_failed: 3
      }.freeze

      VERIFICATION_TIMEOUT = 8.hours

      included do
        sha_attribute :verification_checksum

        # rubocop:disable CodeReuse/ActiveRecord
        scope :verification_pending, -> { available_verifiables.with_verification_state(:verification_pending) }
        scope :verification_started, -> { available_verifiables.with_verification_state(:verification_started) }
        scope :verification_succeeded, -> { available_verifiables.with_verification_state(:verification_succeeded) }
        scope :verification_failed, -> { available_verifiables.with_verification_state(:verification_failed) }
        scope :checksummed, -> { where.not(verification_checksum: nil) }
        scope :not_checksummed, -> { where(verification_checksum: nil) }
        scope :verification_timed_out, -> { verification_started.where("verification_started_at < ?", VERIFICATION_TIMEOUT.ago) }
        scope :retry_due, -> { where(verification_arel_table[:verification_retry_at].eq(nil).or(verification_arel_table[:verification_retry_at].lt(Time.current))) }
        scope :needs_verification, -> { available_verifiables.merge(with_verification_state(:verification_pending).or(with_verification_state(:verification_failed).retry_due)) }
        scope :needs_reverification, -> { verification_succeeded.where("verified_at < ?", ::Gitlab::Geo.current_node.minimum_reverification_interval.days.ago) }
        # rubocop:enable CodeReuse/ActiveRecord

        state_machine :verification_state, initial: :verification_pending do
          state :verification_pending, value: VERIFICATION_STATE_VALUES[:verification_pending]
          state :verification_started, value: VERIFICATION_STATE_VALUES[:verification_started]
          state :verification_succeeded, value: VERIFICATION_STATE_VALUES[:verification_succeeded] do
            validates :verification_checksum, presence: true
          end
          state :verification_failed, value: VERIFICATION_STATE_VALUES[:verification_failed] do
            validates :verification_failure, presence: true
          end

          before_transition any => :verification_started do |instance, _|
            instance.verification_started_at = Time.current
          end

          before_transition [:verification_pending, :verification_started, :verification_succeeded] => :verification_pending do |instance, _|
            instance.clear_verification_failure_fields!
          end

          before_transition verification_failed: :verification_pending do |instance, _|
            # If transitioning from verification_failed, then don't clear
            # verification_retry_count and verification_retry_at to ensure
            # progressive backoff of syncs-due-to-verification-failures
            instance.verification_failure = nil
          end

          before_transition any => :verification_failed do |instance, _|
            instance.before_verification_failed
          end

          before_transition any => :verification_succeeded do |instance, _|
            instance.verified_at = Time.current
            instance.clear_verification_failure_fields!
          end

          event :verification_started do
            transition [:verification_pending, :verification_started, :verification_succeeded, :verification_failed] => :verification_started
          end

          event :verification_succeeded do
            transition verification_started: :verification_succeeded
          end

          event :verification_failed do
            transition [:verification_pending, :verification_started, :verification_succeeded, :verification_failed] => :verification_failed
          end

          event :verification_pending do
            transition [:verification_pending, :verification_started, :verification_succeeded, :verification_failed] => :verification_pending
          end
        end

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
          relation = verification_pending_batch_relation(batch_size: batch_size)

          start_verification_batch(relation)
        end

        # Overridden by Geo::VerifiableRegistry
        def verification_pending_batch_relation(batch_size:)
          verification_pending.order(Gitlab::Database.nulls_first_order(:verified_at)).limit(batch_size) # rubocop:disable CodeReuse/ActiveRecord
        end

        # Returns IDs of records that failed to verify (calculate and save checksum).
        #
        # Atomically marks those records "verification_started" in the same DB
        # query.
        #
        def verification_failed_batch(batch_size:)
          relation = verification_failed_batch_relation(batch_size: batch_size)

          start_verification_batch(relation)
        end

        # Overridden by Geo::VerifiableRegistry
        def verification_failed_batch_relation(batch_size:)
          verification_failed.retry_due.order(Gitlab::Database.nulls_first_order(:verification_retry_at)).limit(batch_size) # rubocop:disable CodeReuse/ActiveRecord
        end

        # @return [Integer] number of records that need verification
        def needs_verification_count(limit:)
          needs_verification_relation.limit(limit).count # rubocop:disable CodeReuse/ActiveRecord
        end

        # Overridden by Geo::VerifiableRegistry
        def needs_verification_relation
          needs_verification
        end

        # @return [Integer] number of records that need reverification
        def needs_reverification_count(limit:)
          needs_reverification.limit(limit).count # rubocop:disable CodeReuse/ActiveRecord
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
            .lock('FOR UPDATE SKIP LOCKED') # rubocop:disable CodeReuse/ActiveRecord
        end

        # Overridden in ReplicableRegistry
        # This method can also be overriden in the replicable model class that
        # includes this concern to specify the primary key of the database
        # table that stores verification state
        # See module EE::MergeRequestDiff for example
        def verification_state_model_key
          self.primary_key
        end

        # Override this method in the class that includes this concern to specify
        # a different database table to store verification state
        # See module EE::MergeRequestDiff for example
        def verification_state_table_name
          table_name
        end

        # Override this method in the class that includes this concern to specify
        # a different arel table to store verification state
        # See module EE::MergeRequestDiff for example
        def verification_arel_table
          arel_table
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

          verification_timed_out.each_batch do |relation|
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
        #
        # rubocop:disable CodeReuse/ActiveRecord
        def reverification_batch_relation(batch_size:)
          needs_reverification.order(:verified_at).limit(batch_size)
        end
        # rubocop:enable CodeReuse/ActiveRecord

        # Atomically marks the records as verification_pending.
        # Returns the number of records set to be referified.
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

      # Overridden by Geo::VerifiableRegistry
      def clear_verification_failure_fields!
        self.verification_retry_count = 0
        self.verification_retry_at = nil
        self.verification_failure = nil
      end

      # Overridden by Geo::VerifiableRegistry
      def before_verification_failed
        self.verification_retry_count ||= 0
        self.verification_retry_count += 1
        self.verification_retry_at = self.next_retry_time(self.verification_retry_count)
        self.verified_at = Time.current
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
        elsif Gitlab::Geo.primary?
          self.replicator.handle_after_checksum_succeeded
        end
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
end
