# frozen_string_literal: true

module EE
  module Ci
    module Queue
      module BuildQueueService
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        override :builds_for_shared_runner
        def builds_for_shared_runner
          # if disaster recovery is enabled, we disable quota
          if ::Feature.enabled?(:ci_queueing_disaster_recovery_disable_quota, runner, type: :ops)
            super
          else
            enforce_minutes_based_on_cost_factors(super)
          end
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def enforce_minutes_based_on_cost_factors(relation)
          strategy.enforce_minutes_limit(relation)
        end
      end
    end
  end
end
