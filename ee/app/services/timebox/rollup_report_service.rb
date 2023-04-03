# frozen_string_literal: true

# rubocop:disable Layout/LineLength
module Timebox
  class RollupReportService
    NULL_STATS_DATA = { incomplete: { count: 0, weight: 0 }, complete: { count: 0, weight: 0 }, total: { count: 0, weight: 0 } }.freeze

    def initialize(timebox, scoped_projects = nil)
      @timebox = timebox
      @scoped_projects = scoped_projects
      @item_states = {}
      @chart_data = []
    end

    def execute
      # There is no data to return for fake timeboxes like
      # Milestone::None, Milestone::Any, Milestone::Started, Milestone::Upcoming,
      # Iteration::None, Iteration::Any, Iteration::Current
      return success if timebox.is_a?(::Timebox::TimeboxStruct)
      return error(:unsupported_type) unless timebox.supports_timebox_charts?
      return error(:missing_dates) if timebox.start_date.blank? || timebox.due_date.blank?

      agg_service_response = Timebox::EventAggregationService.new(timebox, scoped_projects).execute
      return agg_service_response unless agg_service_response.success?

      resource_events = agg_service_response.payload[:resource_events]
      resource_events.each do |event|
        case event['event_type']
        when EventAggregationService::EVENT_TYPE[:timebox]
          handle_resource_timebox_event(event)
        when EventAggregationService::EVENT_TYPE[:state]
          handle_state_event(event)
        when EventAggregationService::EVENT_TYPE[:weight]
          handle_weight_event(event)
        end
      end

      success
    end

    private

    attr_reader :timebox, :item_states, :chart_data, :scoped_projects

    def success
      ServiceResponse.success(payload: {
        burnup_time_series: chart_data,
        stats: build_stats
      })
    end

    def error(code)
      message = case code
                when :unsupported_type then _(format('%{timebox_type} does not support burnup charts', timebox_type: timebox_type))
                when :missing_dates    then _(format('%{timebox_type} must have a start and due date', timebox_type: timebox_type))
                end

      ServiceResponse.error(message: message, payload: { code: code })
    end

    def handle_resource_timebox_event(event)
      item_state = find_or_build_state(event['issue_id'])

      return if item_state[:timebox] == timebox.id && event['action'] == ResourceTimeboxEvent.actions[:add] && event['value'] == timebox.id

      if event['action'] == ResourceTimeboxEvent.actions[:add] && event['value'] == timebox.id
        handle_add_timebox_event(event)
      elsif item_state[:timebox] == timebox.id
        # If the issue is currently assigned to the timebox(milestone or iteration), then treat any event here as a removal.
        # We do not have a separate `:remove` event when replacing timebox(milestone or iteration) with another one.
        handle_remove_timebox_event(event)
      end

      item_state[:timebox] = event['action'] == ResourceTimeboxEvent.actions[:add] ? event['value'] : nil
    end

    def handle_add_timebox_event(event)
      item_state = find_or_build_state(event['issue_id'])

      increment_scope(event['created_at'], item_state[:weight])

      return unless item_state[:state] == ResourceStateEvent.states[:closed]

      increment_completed(event['created_at'], item_state[:weight])
    end

    def handle_remove_timebox_event(event)
      item_state = find_or_build_state(event['issue_id'])

      decrement_scope(event['created_at'], item_state[:weight])

      return unless item_state[:state] == ResourceStateEvent.states[:closed]

      decrement_completed(event['created_at'], item_state[:weight])
    end

    def handle_state_event(event)
      item_state = find_or_build_state(event['issue_id'])
      old_state = item_state[:state]
      item_state[:state] = event['value']

      return if item_state[:timebox] != timebox.id

      if old_state == ResourceStateEvent.states[:closed] && event['value'] == ResourceStateEvent.states[:reopened]
        decrement_completed(event['created_at'], item_state[:weight])
      elsif ResourceStateEvent.states.values_at(:opened, :reopened).include?(old_state) && event['value'] == ResourceStateEvent.states[:closed]
        increment_completed(event['created_at'], item_state[:weight])
      end
    end

    def handle_weight_event(event)
      item_state = find_or_build_state(event['issue_id'])
      old_weight = item_state[:weight]
      item_state[:weight] = event['value'] || 0

      return if item_state[:timebox] != timebox.id

      add_chart_data(event['created_at'], :scope_weight, item_state[:weight] - old_weight)

      return unless item_state[:state] == ResourceStateEvent.states[:closed]

      add_chart_data(event['created_at'], :completed_weight, item_state[:weight] - old_weight)
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

    def find_or_build_state(item_id)
      item_states[item_id] ||= {
        timebox: nil,
        weight: 0,
        state: ResourceStateEvent.states[:opened]
      }
    end

    def timebox_type
      timebox.class.name
    end

    def build_stats
      stats_data = chart_data.last
      return NULL_STATS_DATA unless stats_data

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
end
# rubocop:enable Layout/LineLength
