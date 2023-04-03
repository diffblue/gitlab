# frozen_string_literal: true

module Timebox
  class EventAggregationService
    include Gitlab::Utils::StrongMemoize

    EVENT_TYPE = {
      link: 'link',
      timebox: 'timebox',
      weight: 'weight',
      state: 'state'
    }.freeze

    # A timebox report needs to gather all the events - issue assignment, weight, status - associated with its timebox.
    # To avoid straining the DB and the application hosts,
    # an upperbound needs to be placed on the number of events queried.
    EVENT_COUNT_LIMIT = 50_000

    # While running the UNION query for events, PostgreSQL could still read unlimited amount of buffers.
    # As a safety measure, each subquery in the UNION query should have a limit.
    SINGLE_EVENT_COUNT_LIMIT = 20_000

    def initialize(timebox, scoped_projects = nil)
      @timebox = timebox
      @scoped_projects = scoped_projects
    end

    def execute
      if resource_events.num_tuples > EVENT_COUNT_LIMIT
        return ServiceResponse.error(message: _('Burnup chart could not be generated due to too many events'),
          payload: { code: :too_many_events })
      end

      ServiceResponse.success(payload: { resource_events: resource_events })
    end

    private

    attr_reader :timebox, :scoped_projects

    def resource_events
      ApplicationRecord.connection.execute(resource_events_query)
    end
    strong_memoize_attr :resource_events

    # rubocop: disable CodeReuse/ActiveRecord
    def resource_events_query
      # This service requires the fetched events to be ordered by created_at and id.
      # See the description in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89476.
      union = Gitlab::SQL::Union.new([ # rubocop: disable Gitlab/Union
        resource_timebox_events,
        state_events,
        weight_events
      ])

      Arel::SelectManager.new
        .with(materialized_ctes)
        .project(Arel.star)
        .from("((#{union.to_sql}) ORDER BY created_at, id LIMIT #{EVENT_COUNT_LIMIT + 1}) resource_events_union").to_sql
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def materialized_ctes
      ctes = if scoped_projects.nil?
               [Gitlab::SQL::CTE.new(:scoped_issue_ids, issue_ids)]
             else
               timebox_cte = Gitlab::SQL::CTE.new(:timebox_issue_ids, issue_ids)
               scope_cte = Gitlab::SQL::CTE.new(:scoped_issue_ids,
                 Issue
                   .where(Arel.sql('"issues"."id" IN (SELECT "issue_id" FROM "timebox_issue_ids")'))
                   .in_projects(scoped_projects)
                   .select(:id)
               )

               [timebox_cte, scope_cte]
             end

      ctes.map(&:to_arel)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def resource_timebox_events
      resource_timebox_event_class.by_created_at_earlier_or_equal_to(end_time).by_issue_ids(in_scoped_issue_ids)
        .select("'timebox' AS event_type", "id", "created_at", "#{timebox_fk} AS value", "action", "issue_id")
        .limit(SINGLE_EVENT_COUNT_LIMIT)
    end

    def state_events
      ResourceStateEvent.by_created_at_earlier_or_equal_to(end_time).by_issue_ids(in_scoped_issue_ids)
        .select("'state' AS event_type", "id", "created_at", "state AS value", "NULL AS action", "issue_id")
        .limit(SINGLE_EVENT_COUNT_LIMIT)
    end

    def weight_events
      ResourceWeightEvent.by_created_at_earlier_or_equal_to(end_time).by_issue_ids(in_scoped_issue_ids)
        .select("'weight' AS event_type", "id", "created_at", "weight AS value", "NULL AS action", "issue_id")
        .limit(SINGLE_EVENT_COUNT_LIMIT)
    end

    def in_scoped_issue_ids
      Arel.sql('SELECT * FROM "scoped_issue_ids"')
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def issue_ids
      # We find all issues that have this milestone added before this milestone's due date.
      # We cannot just filter by `issues.milestone_id` because there might be issues that have
      # since been moved to other milestones and we still need to include these in this graph.
      resource_timebox_event_class
        .select(:issue_id)
        .where({
          "#{timebox_fk}": timebox.id,
          action: :add
        })
        .where('created_at <= ?', end_time)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def end_time
      @end_time ||= timebox.due_date.end_of_day
    end

    def timebox_fk
      timebox_type = timebox.class.name

      timebox_type.downcase.foreign_key
    end

    def resource_timebox_event_class
      case timebox
      when Milestone then ResourceMilestoneEvent
      when Iteration then ResourceIterationEvent
      else
        raise ArgumentError, 'Cannot handle timebox type'
      end
    end
  end
end
