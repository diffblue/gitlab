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
            else
              super
            end
          end
        end

        prepended do
          EE_ORPHAN_TYPES = [::Types::WorkItems::Widgets::WeightType].freeze

          orphan_types(*ce_orphan_types, *EE_ORPHAN_TYPES)
        end
      end
    end
  end
end
