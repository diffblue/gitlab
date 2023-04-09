# frozen_string_literal: true

# This service computes the timebox's(milestone, iteration) daily total number of issues and their weights.
# For each day, this returns the totals for all issues that are assigned to the timebox(milestone, iteration) at that point in time.
# This represents the scope for this timebox(milestone, iteration). This also returns separate totals for closed issues which represent the completed work.
#
# This is implemented by iterating over all relevant resource events ordered by time. We need to do this
# so that we can keep track of the issue's state during that point in time and handle the events based on that.

class TimeboxReportService
  include Gitlab::Utils::StrongMemoize

  # A timebox report needs to gather all the events - issue assignment, weight, status - associated with its timebox.
  # To avoid straining the DB and the application hosts, an upperbound needs to be placed on the number of events queried.
  EVENT_COUNT_LIMIT = 50_000

  # While running the UNION query for events, PostgreSQL could still read unlimited amount of buffers.
  # As a safety measure, each subquery in the UNION query should have a limit.
  SINGLE_EVENT_COUNT_LIMIT = 20_000

  def initialize(timebox, scoped_projects = nil)
    @timebox = timebox
    @scoped_projects = scoped_projects
    @issue_states = {}
    @chart_data = []
  end

  def execute
    # There is no data to return for fake timeboxes like
    # Milestone::None, Milestone::Any, Milestone::Started, Milestone::Upcoming,
    # Iteration::None, Iteration::Any, Iteration::Current
    return success if timebox.is_a?(::Timebox::TimeboxStruct)
    return error(:unsupported_type) unless timebox.supports_timebox_charts?
    return error(:missing_dates) if timebox.start_date.blank? || timebox.due_date.blank?
    return error(:too_many_events) if resource_events.num_tuples > EVENT_COUNT_LIMIT

    resource_events.each do |event|
      case event['event_type']
      when 'timebox'
        handle_resource_timebox_event(event)
      when 'state'
        handle_state_event(event)
      when 'weight'
        handle_weight_event(event)
      end
    end

    success
  end

  private

  attr_reader :timebox, :issue_states, :chart_data

  def success
    ServiceResponse.success(payload: {
      burnup_time_series: chart_data,
      stats: build_stats
    })
  end

  def error(code)
    message = case code
              when :unsupported_type then _('%{timebox_type} does not support burnup charts' % { timebox_type: timebox_type })
              when :missing_dates    then _('%{timebox_type} must have a start and due date' % { timebox_type: timebox_type })
              when :too_many_events  then _('Burnup chart could not be generated due to too many events')
              end

    ServiceResponse.error(message: message, payload: { code: code })
  end

  def handle_resource_timebox_event(event)
    issue_state = find_issue_state(event['issue_id'])

    return if issue_state[:timebox] == timebox.id && event['action'] == ResourceTimeboxEvent.actions[:add] && event['value'] == timebox.id

    if event['action'] == ResourceTimeboxEvent.actions[:add] && event['value'] == timebox.id
      handle_add_timebox_event(event)
    elsif issue_state[:timebox] == timebox.id
      # If the issue is currently assigned to the timebox(milestone or iteration), then treat any event here as a removal.
      # We do not have a separate `:remove` event when replacing timebox(milestone or iteration) with another one.
      handle_remove_timebox_event(event)
    end

    issue_state[:timebox] = event['action'] == ResourceTimeboxEvent.actions[:add] ? event['value'] : nil
  end

  def handle_add_timebox_event(event)
    issue_state = find_issue_state(event['issue_id'])

    increment_scope(event['created_at'], issue_state[:weight])

    if issue_state[:state] == ResourceStateEvent.states[:closed]
      increment_completed(event['created_at'], issue_state[:weight])
    end
  end

  def handle_remove_timebox_event(event)
    issue_state = find_issue_state(event['issue_id'])

    decrement_scope(event['created_at'], issue_state[:weight])

    if issue_state[:state] == ResourceStateEvent.states[:closed]
      decrement_completed(event['created_at'], issue_state[:weight])
    end
  end

  def handle_state_event(event)
    issue_state = find_issue_state(event['issue_id'])
    old_state = issue_state[:state]
    issue_state[:state] = event['value']

    return if issue_state[:timebox] != timebox.id

    if old_state == ResourceStateEvent.states[:closed] && event['value'] == ResourceStateEvent.states[:reopened]
      decrement_completed(event['created_at'], issue_state[:weight])
    elsif ResourceStateEvent.states.values_at(:opened, :reopened).include?(old_state) && event['value'] == ResourceStateEvent.states[:closed]
      increment_completed(event['created_at'], issue_state[:weight])
    end
  end

  def handle_weight_event(event)
    issue_state = find_issue_state(event['issue_id'])
    old_weight = issue_state[:weight]
    issue_state[:weight] = event['value'] || 0

    return if issue_state[:timebox] != timebox.id

    add_chart_data(event['created_at'], :scope_weight, issue_state[:weight] - old_weight)

    if issue_state[:state] == ResourceStateEvent.states[:closed]
      add_chart_data(event['created_at'], :completed_weight, issue_state[:weight] - old_weight)
    end
  end

  def increment_scope(timestamp, weight)
    add_chart_data(timestamp, :scope_count, 1)
    add_chart_data(timestamp, :scope_weight, weight)
  end

  def decrement_scope(timestamp, weight)
    add_chart_data(timestamp, :scope_count, -1)
    add_chart_data(timestamp, :scope_weight, -weight)
  end

  def increment_completed(timestamp, weight)
    add_chart_data(timestamp, :completed_count, 1)
    add_chart_data(timestamp, :completed_weight, weight)
  end

  def decrement_completed(timestamp, weight)
    add_chart_data(timestamp, :completed_count, -1)
    add_chart_data(timestamp, :completed_weight, -weight)
  end

  def add_chart_data(timestamp, field, value)
    date = timestamp.to_date
    date = timebox.start_date if date < timebox.start_date

    if chart_data.empty?
      chart_data.push({
        date: date,
        scope_count: 0,
        scope_weight: 0,
        completed_count: 0,
        completed_weight: 0
      })
    elsif chart_data.last[:date] != date
      # To start a new day entry we copy the previous day's data because the numbers are cumulative
      chart_data.push(
        chart_data.last.merge(date: date)
      )
    end

    chart_data.last[field] += value
  end

  def find_issue_state(issue_id)
    issue_states[issue_id] ||= {
      timebox: nil,
      weight: 0,
      state: ResourceStateEvent.states[:opened]
    }
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def materialized_ctes
    ctes = if @scoped_projects.nil?
             [Gitlab::SQL::CTE.new(:scoped_issue_ids, issue_ids)]
           else
             timebox_cte = Gitlab::SQL::CTE.new(:timebox_issue_ids, issue_ids)
             scope_cte = Gitlab::SQL::CTE.new(:scoped_issue_ids,
               Issue
                .where(Arel.sql('"issues"."id" IN (SELECT "issue_id" FROM "timebox_issue_ids")'))
                .in_projects(@scoped_projects)
                .select(:id)
             )

             [timebox_cte, scope_cte]
           end

    ctes.map { |cte| cte.to_arel }
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def resource_events_query
    # This service requires the fetched events to be ordered by created_at and id.
    # See the description in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89476.
    union = Gitlab::SQL::Union.new([resource_timebox_events, state_events, weight_events]) # rubocop: disable Gitlab/Union

    Arel::SelectManager.new
      .with(materialized_ctes)
      .project(Arel.star)
      .from("((#{union.to_sql}) ORDER BY created_at, id LIMIT #{EVENT_COUNT_LIMIT + 1}) resource_events_union").to_sql
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def resource_events
    strong_memoize(:resource_events) do
      ApplicationRecord.connection.execute(resource_events_query)
    end
  end

  def resource_timebox_events
    resource_timebox_event_class.by_created_at_earlier_or_equal_to(end_time).by_issue_ids(in_scoped_issue_ids)
      .aliased_for_timebox_report
      .limit(SINGLE_EVENT_COUNT_LIMIT)
  end

  def state_events
    ResourceStateEvent.by_created_at_earlier_or_equal_to(end_time).by_issue_ids(in_scoped_issue_ids)
      .aliased_for_timebox_report
      .limit(SINGLE_EVENT_COUNT_LIMIT)
  end

  def weight_events
    ResourceWeightEvent.by_created_at_earlier_or_equal_to(end_time).by_issue_ids(in_scoped_issue_ids)
      .aliased_for_timebox_report
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

  def timebox_type
    timebox.class.name
  end

  def timebox_fk
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

  def build_stats
    stats_data = chart_data.last
    return unless stats_data

    {
      complete: {
        count: stats_data[:completed_count],
        weight: stats_data[:completed_weight]
      },
      incomplete: {
        count: stats_data[:scope_count] - stats_data[:completed_count],
        weight: stats_data[:scope_weight] - stats_data[:completed_weight]
      },
      total: {
        count: stats_data[:scope_count],
        weight: stats_data[:scope_weight]
      }
    }
  end
end
