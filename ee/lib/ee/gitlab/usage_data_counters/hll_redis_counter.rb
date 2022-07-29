# frozen_string_literal: true

module EE
  module Gitlab
    module UsageDataCounters
      module HLLRedisCounter
        extend ActiveSupport::Concern
        EE_KNOWN_EVENTS_PATH = File.expand_path('known_events/*.yml', __dir__)
        EE_CATEGORIES_COLLECTED_FROM_METRICS_DEFINITIONS = %w[
          compliance
        ].freeze

        class_methods do
          extend ::Gitlab::Utils::Override

          override :valid_context_list
          def valid_context_list
            super + License.all_plans
          end

          override :known_events
          def known_events
            @known_events ||= (super + load_events(EE_KNOWN_EVENTS_PATH))
          end

          override :categories_collected_from_metrics_definitions
          def categories_collected_from_metrics_definitions
            (EE_CATEGORIES_COLLECTED_FROM_METRICS_DEFINITIONS + super).freeze
          end
        end
      end
    end
  end
end
