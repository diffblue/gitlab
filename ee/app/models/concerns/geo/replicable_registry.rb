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

  # Overridden by Geo::VerifiableRegistry
  def after_synced
    # No-op
  end

  def replicator_class
    Gitlab::Geo::Replicator.for_class_name(self)
  end

  included do
    include ::Delay

    scope :failed, -> { with_state(:failed) }
    scope :needs_sync_again, -> { failed.retry_due.order(Gitlab::Database.nulls_first_order(:retry_at)) }
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
        registry.retry_at = 0
        registry.retry_count = 0
      end

      before_transition any => :failed do |registry, _|
        registry.retry_count += 1
        registry.retry_at = registry.next_retry_time(registry.retry_count)
      end

      before_transition any => :synced do |registry, _|
        registry.retry_count = 0
        registry.last_sync_failure = nil
        registry.retry_at = nil
      end

      after_transition any => :synced do |registry, _|
        registry.after_synced
      end

      event :start do
        transition [:pending, :synced, :failed] => :started
      end

      event :synced do
        transition [:started] => :synced
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
    def failed!(message, error = nil)
      self.last_sync_failure = message
      self.last_sync_failure += ": #{error.message}" if error.respond_to?(:message)
      self.last_sync_failure.truncate(255)

      super()
    end

    def replicator
      self.class.replicator_class.new(model_record_id: model_record_id)
    end
  end
end
