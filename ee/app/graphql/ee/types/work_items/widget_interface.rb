# frozen_string_literal: true

module EE
  module Types
    module WorkItems
      module WidgetInterface
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override

          override :resolve_type
          def resolve_type(object, context)
            case object
            when ::WorkItems::Widgets::Weight
              ::Types::WorkItems::Widgets::WeightType
            when ::WorkItems::Widgets::Status
              ::Types::WorkItems::Widgets::StatusType
            when ::WorkItems::Widgets::Iteration
              ::Types::WorkItems::Widgets::IterationType
            when ::WorkItems::Widgets::HealthStatus
              ::Types::WorkItems::Widgets::HealthStatusType
            when ::WorkItems::Widgets::Progress
              ::Types::WorkItems::Widgets::ProgressType
            when ::WorkItems::Widgets::RequirementLegacy
              ::Types::WorkItems::Widgets::RequirementLegacyType
            when ::WorkItems::Widgets::TestReports
              ::Types::WorkItems::Widgets::TestReportsType
            else
              super
            end
          end
        end

        prepended do
          EE_ORPHAN_TYPES = [
            ::Types::WorkItems::Widgets::WeightType,
            ::Types::WorkItems::Widgets::StatusType,
            ::Types::WorkItems::Widgets::IterationType,
            ::Types::WorkItems::Widgets::HealthStatusType,
            ::Types::WorkItems::Widgets::ProgressType,
            ::Types::WorkItems::Widgets::RequirementLegacyType,
            ::Types::WorkItems::Widgets::TestReportsType
          ].freeze

          orphan_types(*ce_orphan_types, *EE_ORPHAN_TYPES)
        end
      end
    end
  end
end
