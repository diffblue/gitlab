# frozen_string_literal: true

module EE
  module WorkItems
    module Type
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      EE_WIDGETS_FOR_TYPE = {
        issue: [::WorkItems::Widgets::Iteration, ::WorkItems::Widgets::Weight, ::WorkItems::Widgets::HealthStatus],
        requirement: [::WorkItems::Widgets::Status, ::WorkItems::Widgets::RequirementLegacy],
        task: [::WorkItems::Widgets::Iteration, ::WorkItems::Widgets::Weight],
        objective: [::WorkItems::Widgets::HealthStatus, ::WorkItems::Widgets::Progress],
        key_result: [::WorkItems::Widgets::HealthStatus, ::WorkItems::Widgets::Progress]
      }.freeze

      class_methods do
        extend ::Gitlab::Utils::Override

        override :available_widgets
        def available_widgets
          [*EE_WIDGETS_FOR_TYPE.values.flatten.uniq, *super]
        end
      end

      override :widgets
      def widgets
        [*EE_WIDGETS_FOR_TYPE[base_type.to_sym], *super]
      end
    end
  end
end
