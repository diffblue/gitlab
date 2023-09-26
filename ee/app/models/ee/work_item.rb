# frozen_string_literal: true

module EE
  module WorkItem
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include FilterableByTestReports

      has_one :progress, class_name: 'WorkItems::Progress', foreign_key: 'issue_id', inverse_of: :work_item

      delegate :reminder_frequency, to: :progress, allow_nil: true

      scope :with_reminder_frequency, ->(frequency) {
                                        joins(:progress).where(work_item_progresses: { reminder_frequency: frequency })
                                      }
      scope :without_parent, -> {
                               where("NOT EXISTS (SELECT FROM work_item_parent_links WHERE work_item_id = issues.id)")
                             }
      scope :with_assignees, -> { joins(:issue_assignees).includes(:assignees) }
      scope :with_descendents_of, ->(ids) {
                                    joins(:work_item_parent).where(work_item_parent_links: { work_item_parent_id: ids })
                                  }
      scope :with_previous_reminder_sent_before, ->(datetime) do
        left_joins(:progress).where(
          "work_item_progresses.last_reminder_sent_at IS NULL
          OR work_item_progresses.last_reminder_sent_at <= ?",
          datetime
        )
      end
      scope :grouped_by_work_item, -> { group(:id) }
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

    override :linked_work_items_query
    def linked_work_items_query(link_type)
      case link_type
      when ::WorkItems::RelatedWorkItemLink::TYPE_BLOCKS
        blocking_work_items_query
      when ::WorkItems::RelatedWorkItemLink::TYPE_IS_BLOCKED_BY
        blocking_work_items_query(inverse_direction: true)
      else
        super
      end
    end

    def blocking_work_items_query(inverse_direction: false)
      link_class = ::WorkItems::RelatedWorkItemLink
      columns = %w[target_id source_id]
      columns.reverse! if inverse_direction

      linked_issues_select
        .joins("INNER JOIN issue_links ON issue_links.#{columns[0]} = issues.id")
        .where(issue_links: { columns[1] => id, link_type: link_class.link_types[link_class::TYPE_BLOCKS] })
    end
  end
end
