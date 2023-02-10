# frozen_string_literal: true

module Geo
  module VerificationStateDefinition
    extend ActiveSupport::Concern
    include Delay
    include EachBatch

    included do
      state_machine :verification_state, initial: :verification_pending do
        state :verification_pending, value: VerificationState::VERIFICATION_STATE_VALUES[:verification_pending]
        state :verification_started, value: VerificationState::VERIFICATION_STATE_VALUES[:verification_started]
        state :verification_succeeded, value: VerificationState::VERIFICATION_STATE_VALUES[:verification_succeeded] do
          validates :verification_checksum, presence: true
        end
        state :verification_failed, value: VerificationState::VERIFICATION_STATE_VALUES[:verification_failed] do
          validates :verification_failure, presence: true
        end
        state :verification_disabled, value: VerificationState::VERIFICATION_STATE_VALUES[:verification_disabled]

        before_transition any => :verification_started do |instance, _|
          instance.verification_started_at = Time.current
        end

        before_transition [:verification_pending, :verification_started, :verification_succeeded, :verification_disabled] => :verification_pending do |instance, _|
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
          transition [:verification_pending, :verification_started, :verification_succeeded, :verification_failed, :verification_disabled] => :verification_started
        end

        event :verification_succeeded do
          transition verification_started: :verification_succeeded
        end

        event :verification_failed do
          transition [:verification_pending, :verification_started, :verification_succeeded, :verification_failed, :verification_disabled] => :verification_failed
        end

        event :verification_disabled do
          transition [:verification_pending, :verification_started, :verification_succeeded, :verification_failed, :verification_disabled] => :verification_disabled
        end

        event :verification_pending do
          transition [:verification_pending, :verification_started, :verification_succeeded, :verification_failed, :verification_disabled] => :verification_pending
        end
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
  end
end
