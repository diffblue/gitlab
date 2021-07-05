# frozen_string_literal: true

module Geo
  module Batch
    # Responsible for scheduling multiple jobs to mark Project Registries as requiring syncing or verification.
    #
    # This class includes an Exclusive Lease guard and only one can be executed at the same time
    # If multiple jobs are scheduled, only one will run and the others will drop forever.
    class ProjectRegistrySchedulerWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3
      include GeoQueue
      include ExclusiveLeaseGuard
      include ::Gitlab::Geo::LogHelpers

      BATCH_SIZE = 10000
      LEASE_TIMEOUT = 2.minutes # TTL for X amount of loops to happen until it is renewed
      RENEW_AFTER_LOOPS = 20 # renew lease at every 20 loops has finished
      OPERATIONS = [:resync_repositories, :reverify_repositories].freeze
      DELAY_INTERVAL = 10.seconds.to_i # base delay for scheduling batch execution

      loggable_arguments 0

      def perform(operation)
        return fail_invalid_operation!(operation) unless OPERATIONS.include?(operation.to_sym)

        try_obtain_lease do
          perform_in_batches_with_range(operation.to_sym)
        end
      end

      private

      def perform_in_batches_with_range(operation)
        Geo::ProjectRegistry.each_batch(of: BATCH_SIZE) do |batch, index|
          delay = index * DELAY_INTERVAL

          ::Geo::Batch::ProjectRegistryWorker.perform_in(delay, operation, batch.range)

          renew_lease! if index % RENEW_AFTER_LOOPS == 0 # we renew after X amount of loops to not add much delay here
        end
      end

      def lease_timeout
        LEASE_TIMEOUT
      end

      def fail_invalid_operation!(operation)
        raise ArgumentError, "Invalid operation: '#{operation.inspect}' informed. Must be one of the following: #{OPERATIONS.map { |valid_op| "'#{valid_op}'" }.join(', ')}"
      end
    end
  end
end
