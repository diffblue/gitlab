# frozen_string_literal: true

module Geo
  # Fail verification for records which started verification a long time ago
  class VerificationTimeoutWorker
    include ApplicationWorker

    data_consistency :always
    include GeoQueue
    include ::Gitlab::Geo::LogHelpers

    idempotent!
    sidekiq_options retry: false, dead: false
    tags :exclude_from_kubernetes, :exclude_from_gitlab_com
    loggable_arguments 0

    def perform(replicable_name)
      replicator_class_for(replicable_name).fail_verification_timeouts
    end

    def replicator_class_for(replicable_name)
      @replicator_class ||= ::Gitlab::Geo::Replicator.for_replicable_name(replicable_name)
    end
  end
end
