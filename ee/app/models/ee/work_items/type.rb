# frozen_string_literal: true

module EE
  module WorkItems
    module Type
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      EE_WIDGETS_FOR_TYPE = {
        issue: [::WorkItems::Widgets::Weight],
        requirement: [::WorkItems::Widgets::VerificationStatus],
        task: [::WorkItems::Widgets::Weight]
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
