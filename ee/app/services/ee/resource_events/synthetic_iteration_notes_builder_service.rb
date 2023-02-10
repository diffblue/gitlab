# frozen_string_literal: true

# We store events about resource iteration changes in a separate table,
# but we still want to display notes about iteration changes
# as classic system notes in UI. This service generates "synthetic" notes for
# iteration event changes.

module EE
  module ResourceEvents
    class SyntheticIterationNotesBuilderService < ::ResourceEvents::BaseSyntheticNotesBuilderService
      private

      def synthetic_notes
        iteration_change_events.map do |event|
          IterationNote.from_event(event, resource: resource, resource_parent: resource_parent)
        end
      end

      def iteration_change_events
        return [] unless resource.respond_to?(:resource_iteration_events)

        events = resource.resource_iteration_events.includes(:iteration, user: :status) # rubocop: disable CodeReuse/ActiveRecord
        apply_common_filters(events)
      end

      def table_name
        'resource_iteration_events'
      end
    end
  end
end
