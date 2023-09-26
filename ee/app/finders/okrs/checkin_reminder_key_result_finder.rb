# frozen_string_literal: true

module Okrs
  class CheckinReminderKeyResultFinder
    def initialize(frequency, date = Date.today)
      @frequency = frequency
      @date = date
    end

    def execute
      WorkItem
        .with_state('opened')
        .with_issue_type(:key_result)
        .with_assignees
        .with_descendents_of(
          ::Gitlab::WorkItems::WorkItemHierarchy.new(
            WorkItem
              .with_reminder_frequency(@frequency)
              .with_state('opened')
              .with_issue_type(:objective)
              .without_parent
          ).base_and_descendant_ids
        )
        .with_previous_reminder_sent_before(frequency_reminder_date)
        .group(:id) # rubocop: disable CodeReuse/ActiveRecord
    end

    private

    def frequency_reminder_date
      case @frequency
      when 'monthly'
        @date - 27.days
      when 'twice_monthly'
        @date - 13.days
      when 'weekly'
        @date - 6.days
      end
    end
  end
end
