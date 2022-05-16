# frozen_string_literal: true

class WorkItem < Issue
  self.table_name = 'issues'
  self.inheritance_column = :_type_disabled

  def noteable_target_type_name
    'issue'
  end

  def widgets
    work_item_type.widgets.map do |widget_class|
      widget_class.new(self)
    end
  end

  private

  def record_create_action
    super

    Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter.track_work_item_created_action(author: author)
  end
end
