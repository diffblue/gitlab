# frozen_string_literal: true

module Ci
  module Minutes
    class UpdateProjectAndNamespaceUsageWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker
      include PipelineBackgroundQueue

      urgency :low
      data_consistency :always # primarily performs writes

      # Ensure with retries we stay within the IDEMPOTENCY_CACHE_TTL
      # used by the service object.
      sidekiq_options retry: 3

      def perform(consumption, project_id, namespace_id, build_id)
        ::Ci::Minutes::UpdateProjectAndNamespaceUsageService
          .new(project_id, namespace_id, build_id)
          .execute(consumption)
      end
    end
  end
end
