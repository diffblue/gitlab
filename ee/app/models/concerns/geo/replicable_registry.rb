# frozen_string_literal: true

module Geo::ReplicableRegistry
  extend ActiveSupport::Concern

  STATE_VALUES = {
    pending: 0,
    started: 1,
    synced: 2,
    failed: 3
  }.freeze

  class_methods do
    include Delay

    def state_value(state_string)
      STATE_VALUES[state_string]
    end

    def for_model_record_id(id)
      find_or_initialize_by(self::MODEL_FOREIGN_KEY => id)
    end

    def declarative_policy_class
      'Geo::RegistryPolicy'
    end

    def registry_consistency_worker_enabled?
      replicator_class.enabled?
    end

    # Fail syncs for records which started syncing a long time ago
    def fail_sync_timeouts
      attrs = {
        state: state_value(:failed),
        last_sync_failure: "Sync timed out after #{replicator_class.sync_timeout}",
        retry_count: 1,
        retry_at: next_retry_time(1)
      }

      sync_timed_out.all.each_batch do |relation|
        relation.update_all(attrs)
      end
    end
  end

  def before_synced
    self.retry_count = 0
    self.last_sync_failure = nil
    self.retry_at = nil
  end

  # Overridden by Geo::VerifiableRegistry
  def after_synced
    # No-op
  end

  def replicator_class
    Gitlab::Geo::Replicator.for_class_name(self)
  end

  included do
    include ::Delay

    attr_accessor :custom_max_retry_wait_time

    scope :failed, -> { with_state(:failed) }
    scope :needs_sync_again, -> { failed.retry_due.order(arel_table[:retry_at].asc.nulls_first) }
    scope :never_attempted_sync, -> { pending.where(last_synced_at: nil) }
    scope :ordered, -> { order(:id) }
    scope :pending, -> { with_state(:pending) }
    scope :retry_due, -> { where(arel_table[:retry_at].eq(nil).or(arel_table[:retry_at].lt(Time.current))) }
    scope :synced, -> { with_state(:synced) }
    scope :sync_timed_out, -> { with_state(:started).where("last_synced_at < ?", replicator_class.sync_timeout.ago) }

    state_machine :state, initial: :pending do
      state :pending, value: STATE_VALUES[:pending]
      state :started, value: STATE_VALUES[:started]
      state :synced, value: STATE_VALUES[:synced]
      state :failed, value: STATE_VALUES[:failed]

      before_transition any => :started do |registry, _|
        registry.last_synced_at = Time.current
      end

      before_transition any => :pending do |registry, _|
        registry.retry_at = nil
        registry.retry_count = 0
      end

      before_transition any => :failed do |registry, _|
        registry.retry_count += 1
        registry.retry_at = registry.next_retry_time(registry.retry_count, registry.custom_max_retry_wait_time)
      end

      before_transition any => :synced do |registry, _|
        registry.before_synced
      end

      after_transition any => :synced do |registry, _|
        registry.after_synced
      end

      event :pending do
        transition [:pending, :started, :synced, :failed] => :pending
      end

      event :start do
        transition [:pending, :synced, :failed] => :started
      end

      event :failed do
        transition [:started, :synced] => :failed
      end

      event :resync do
        transition [:synced, :failed] => :pending
      end
    end

    # Override state machine failed! event method to record a failure message at
    # the same time.
    #
    # @param [String] message error information
    # @param [StandardError] error exception
    # @param [Boolean] missing_on_primary if the resource is missing on the primary
    def failed!(message:, error: nil, missing_on_primary: nil)
      self.last_sync_failure = message
      self.last_sync_failure += ": #{error.message}" if error.respond_to?(:message)
      self.last_sync_failure = self.last_sync_failure.truncate(255)
      self.custom_max_retry_wait_time = missing_on_primary ? 4.hours : nil

      super()
    end

    # Override state machine synced! event method to indicate that the sync
    # succeeded (but separately mark as synced atomically).
    #
    # @return [Boolean] whether the update was successful
    def synced!
      before_synced
      save!

      return false unless mark_synced_atomically

      after_synced

      true
    end

    # Mark the resource as synced using atomic conditions
    #
    # @return [Boolean] whether the update was successful
    def mark_synced_atomically
      # We can only update registry if state is started.
      # If state is set to pending that means that pending! was called
      # during the sync so we need to reschedule new sync
      num_rows = self.class
                     .where(self.class::MODEL_FOREIGN_KEY => model_record_id)
                     .with_state(:started)
                     .update_all(state: Geo::ReplicableRegistry::STATE_VALUES[:synced])

      num_rows > 0
    end

    def replicator
      self.class.replicator_class.new(model_record_id: model_record_id)
    end
  end
end
