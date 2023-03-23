# frozen_string_literal: true

module EE
  module WorkItem
    extend ActiveSupport::Concern

    prepended do
      include FilterableByTestReports

      has_one :progress, class_name: 'WorkItems::Progress', foreign_key: 'issue_id', inverse_of: :work_item
    end

    LICENSED_WIDGETS = {
      iterations: ::WorkItems::Widgets::Iteration,
      issue_weights: ::WorkItems::Widgets::Weight,
      requirements: [
        ::WorkItems::Widgets::Status,
        ::WorkItems::Widgets::RequirementLegacy,
        ::WorkItems::Widgets::TestReports
      ],
      issuable_health_status: ::WorkItems::Widgets::HealthStatus,
      okrs: ::WorkItems::Widgets::Progress
    }.freeze

    def widgets
      strong_memoize(:widgets) do
        allowed_widgets = work_item_type.widgets - unlicensed_widgets

        allowed_widgets.map do |widget_class|
          widget_class.new(self)
        end
      end
    end

    def average_progress_of_children
      children = work_item_children
      child_count = children.count
      return 0 unless child_count > 0

      (::WorkItems::Progress.where(work_item: children).sum(:progress).to_i / child_count).to_i
    end

    private

    def unlicensed_widgets
      excluded = LICENSED_WIDGETS.map do |licensed_feature, widgets|
        widgets unless resource_parent.licensed_feature_available?(licensed_feature)
      end
      excluded.flatten
    end
  end
end
