# frozen_string_literal: true

module EE
  module WorkItem
    extend ActiveSupport::Concern

    LICENSED_WIDGETS = {
      issue_weights: ::WorkItems::Widgets::Weight,
      requirements: ::WorkItems::Widgets::VerificationStatus
    }.freeze

    def widgets
      strong_memoize(:widgets) do
        allowed_widgets = work_item_type.widgets - unlicensed_widgets

        allowed_widgets.map do |widget_class|
          widget_class.new(self)
        end
      end
    end

    private

    def unlicensed_widgets
      LICENSED_WIDGETS.map do |licensed_feature, widget|
        widget unless resource_parent.licensed_feature_available?(licensed_feature)
      end
    end
  end
end
