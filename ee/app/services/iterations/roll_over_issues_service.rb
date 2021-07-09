# frozen_string_literal: true

module Iterations
  class RollOverIssuesService
    PermissionsError = Class.new(StandardError)

    BATCH_SIZE = 100

    def initialize(user, from_iteration, to_iteration)
      @user = user
      @from_iteration = from_iteration
      @to_iteration = to_iteration
    end

    def execute
      return ::ServiceResponse.error(message: _('Operation not allowed'), http_status: 403) unless can_roll_over_issues?

      from_iteration.issues.opened.each_batch(of: BATCH_SIZE) do |issues|
        add_iteration_events, remove_iteration_events = iteration_events(issues)

        ApplicationRecord.transaction do
          issues.update_all(sprint_id: to_iteration.id, updated_at: rolled_over_at)
          Gitlab::Database.bulk_insert(ResourceIterationEvent.table_name, remove_iteration_events) # rubocop:disable Gitlab/BulkInsert
          Gitlab::Database.bulk_insert(ResourceIterationEvent.table_name, add_iteration_events) # rubocop:disable Gitlab/BulkInsert
        end
      end

      ::ServiceResponse.success
    end

    private

    attr_reader :user, :from_iteration, :to_iteration

    def iteration_events(issues)
      add_iteration_events = []
      remove_iteration_events = []
      issues.map do |issue|
        remove_iteration_events << common_event_attributes(issue).merge({ iteration_id: issue.sprint_id, action: ResourceTimeboxEvent.actions[:remove] })
        add_iteration_events << common_event_attributes(issue).merge({ iteration_id: to_iteration.id, action: ResourceTimeboxEvent.actions[:add] })
      end

      [add_iteration_events, remove_iteration_events]
    end

    def common_event_attributes(issue)
      {
        created_at: rolled_over_at,
        user_id: user.id,
        issue_id: issue.id
      }
    end

    def can_roll_over_issues?
      user && to_iteration && from_iteration &&
        !to_iteration.closed? && to_iteration.due_date > rolled_over_at.to_date &&
        (user.automation_bot? || user.can?(:rollover_issues, to_iteration))
    end

    def rolled_over_at
      @rolled_over_at ||= Time.current
    end
  end
end
