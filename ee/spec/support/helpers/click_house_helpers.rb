# frozen_string_literal: true

module ClickHouseHelpers
  def format_event_row(event)
    path = event.project.reload.project_namespace.traversal_ids.join('/')

    action = Event.actions[event.action]
    [
      event.id,
      "'#{path}/'",
      event.author_id,
      event.target_id,
      "'#{event.target_type}'",
      action,
      event.created_at.to_f,
      event.updated_at.to_f
    ].join(',')
  end

  def insert_events_into_click_house(events = Event.all)
    rows = events.map { |event| "(#{format_event_row(event)})" }.join(',')

    insert_query = <<~SQL
    INSERT INTO events
    (id, path, author_id, target_id, target_type, action, created_at, updated_at)
    VALUES
    #{rows}
    SQL

    ClickHouse::Client.execute(insert_query, :main)
  end
end
