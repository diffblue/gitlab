# frozen_string_literal: true

module Gitlab
  module Timebox
    class SnapshotBuilder
      ArgumentError = Class.new(StandardError)
      FieldsError = Class.new(StandardError)

      REQUIRED_RESOURCE_EVENT_FIELDS = %w[id event_type issue_id value action created_at].freeze

      # This class builds snapshots of issue or work item states for a timebox
      # based on their relevant resource events.
      #
      # timebox - the timebox (either milestone or iteration) of interest
      # resource_events - PG::Result of a query for resource events.
      #   Resource event models must select the correct columns
      #   using the scope "aliased_for_timebox_report" and ordered by creation date.
      def initialize(timebox, resource_events)
        @resource_events = resource_events
        @timebox = timebox
        @item_states = {}
      end

      def build
        check_arguments!

        @snapshots = []

        return @snapshots if @resource_events.ntuples < 1

        timebox_date_range.each do |snapshot_date|
          next_date = snapshot_date + 1.day
          @resource_events
            .take_while { |event| event['created_at'] < next_date }
            .each do |event|
              case event['event_type']
              when ::Timebox::EventAggregationService::EVENT_TYPE[:timebox]
                handle_resource_timebox_event(event)
              when ::Timebox::EventAggregationService::EVENT_TYPE[:state]
                handle_state_event(event)
              when ::Timebox::EventAggregationService::EVENT_TYPE[:weight]
                handle_weight_event(event)
              when ::Timebox::EventAggregationService::EVENT_TYPE[:link]
                handle_resource_link_event(event)
              end
            end

          take_snapshot(snapshot_date: snapshot_date)

          @resource_events = @resource_events.reject { |event| event['created_at'] < next_date }
        end

        @snapshots
      end

      private

      attr_reader :timebox, :item_states

      def check_arguments!
        raise ArgumentError unless timebox.is_a?(Milestone) || timebox.is_a?(Iteration)
        raise ArgumentError unless @resource_events.is_a? PG::Result
        raise FieldsError unless valid_resource_event_columns?
      end

      def valid_resource_event_columns?
        REQUIRED_RESOURCE_EVENT_FIELDS
          .map { |column| @resource_events.fields.include? column }
          .all? true
      end

      def timebox_date_range
        return timebox.start_date..Date.current if Date.current < timebox.due_date

        timebox.start_date..timebox.due_date
      end

      def take_snapshot(snapshot_date:)
        snapshot = item_states.map do |id, item|
          prev_item_state = @snapshots.last[:item_states].find { |i| i[:item_id] == id } if @snapshots.any?

          {
            item_id: id,
            timebox_id: item[:timebox],
            weight: item[:weight],
            start_state: prev_item_state ? prev_item_state[:end_state] : ResourceStateEvent.states[:opened],
            end_state: item[:state],
            parent_id: item[:parent_id],
            children_ids: Set.new(item[:children_ids])
          }
        end

        @snapshots.push({ date: snapshot_date, item_states: snapshot })
      end

      def handle_resource_timebox_event(event)
        item_state = find_or_build_state(event['issue_id'])

        is_add_event = event['action'] == ResourceTimeboxEvent.actions[:add]
        target_timebox_id = event['value']

        return if item_state[:timebox] == timebox.id && is_add_event && target_timebox_id == timebox.id

        item_state[:timebox] = is_add_event ? target_timebox_id : nil

        # If the issue is currently assigned to the timebox(milestone or iteration),
        # then treat any event here as a removal.
        # We do not have a separate `:remove` event when replacing timebox(milestone or iteration) with another one.
        item_state[:timebox] = target_timebox_id if item_state[:timebox] == timebox.id
      end

      def handle_state_event(event)
        item_state = find_or_build_state(event['issue_id'])
        item_state[:state] = event['value']
      end

      def handle_weight_event(event)
        item_state = find_or_build_state(event['issue_id'])
        item_state[:weight] = event['value'] || 0
      end

      def handle_resource_link_event(event)
        child_id = event['value']
        parent_id = event['issue_id']
        child = find_or_build_state(child_id)
        parent = find_or_build_state(parent_id)

        case event['action']
        when ::WorkItems::ResourceLinkEvent.actions[:add]
          child[:parent_id] = parent_id
          parent[:children_ids] << child_id
        when ::WorkItems::ResourceLinkEvent.actions[:remove]
          parent[:children_ids].delete(child_id)
          child[:parent_id] = nil
        end
      end

      def find_or_build_state(issue_id)
        item_states[issue_id] ||= {
          timebox: nil,
          weight: 0,
          state: ResourceStateEvent.states[:opened],
          parent_id: nil,
          children_ids: Set.new
        }
      end
    end
  end
end
