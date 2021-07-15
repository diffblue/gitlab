# frozen_string_literal: true

module EE
  module Gitlab
    module UsageDataCounters
      module HLLRedisCounter
        extend ActiveSupport::Concern
        class_methods do
          extend ::Gitlab::Utils::Override

          override :valid_context_list
          def valid_context_list
            super + License.all_plans
          end

          override :usage_ping_enabled?
          def usage_ping_enabled?
            ::License.current&.customer_service_enabled? || super
          end
        end
      end
    end
  end
end
