# frozen_string_literal: true

module Geo
  module VerifiableRegistry
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override
    include ::Geo::VerificationState
    include ::Geo::VerificationStateDefinition

    class_methods do
      extend ::Gitlab::Utils::Override

      # Overrides a method in `::Geo::VerificationState`. This method is
      # used by `::Geo::VerificationState.start_verification_batch` to
      # produce a query which must return values of the primary key of the
      # *model*, not of the *registry*. We need this so we can instantiate
      # Replicators.
      override :verification_state_model_key
      def verification_state_model_key
        self::MODEL_FOREIGN_KEY
      end
    end

    included do
      extend ::Gitlab::Utils::Override

      sha_attribute :verification_checksum_mismatched

      scope :available_verifiables, -> { synced }

      override :clear_verification_failure_fields!
      def clear_verification_failure_fields!
        super

        # Note: If the return value of a `before_transition` block is `false`,
        # then the transition is halted. Anything else, including `nil`, does not
        # halt the transition.
        self.checksum_mismatch = false
        self.verification_checksum_mismatched = nil
      end

      # Records a checksum mismatch
      #
      # @param [String] checksum value which does not match the primary checksum
      def verification_failed_due_to_mismatch!(checksum, primary_checksum)
        message = 'Checksum does not match the primary checksum'
        details = { checksum: checksum, primary_checksum: primary_checksum }

        log_info(message, details)

        self.verification_failure = "#{message} #{details}".truncate(255)
        self.verification_checksum = checksum
        self.verification_checksum_mismatched = checksum
        self.checksum_mismatch = true

        self.verification_failed!
      end

      override :track_checksum_attempt!
      def track_checksum_attempt!(&block)
        unless ready_to_verify?
          self.verification_disabled!
          return
        end

        super
      end

      private

      override :track_checksum_result!
      def track_checksum_result!(checksum, calculation_started_at)
        unless replicator.matches_checksum?(checksum)
          return verification_failed_due_to_mismatch!(checksum, replicator.primary_checksum)
        end

        verification_succeeded_with_checksum!(checksum, calculation_started_at)
      end
    end

    override :after_synced
    def after_synced
      unless ready_to_verify?
        self.verification_disabled!
        return
      end

      self.verification_pending!
    end

    def ready_to_verify?
      replicator.primary_verification_succeeded?
    end

    override :before_verification_failed
    def before_verification_failed
      # Let verification failure fields get set as usual
      super

      # When this registry became synced, retry_count was set to 0. This line
      # ensures that resyncs due to verification failures use progressive
      # backoff behavior. One is subtracted to compensate for 1 being
      # automatically added to `retry_count` on transition to failed.
      self.retry_count = self.verification_retry_count - 1

      self.last_sync_failure = "Verification failed with: #{verification_failure}".truncate(255)

      # This registry was successfully synced, and now it has failed
      # verification. This line makes Geo automatically resync it.
      self.failed
    end
  end
end
