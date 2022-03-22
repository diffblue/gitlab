# frozen_string_literal: true

module SystemNotes
  class IncidentsService < ::SystemNotes::BaseService
    def initialize(noteable:)
      @noteable = noteable
      @project = noteable.project
    end

    def add_timeline_event(timeline_event)
      author = timeline_event.author
      anchor = "timeline_event_#{timeline_event.id}"
      path = url_helpers.project_issues_incident_path(project, noteable, anchor: anchor)
      body = "added an [incident timeline event](#{path})"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'timeline_event'))
    end
  end
end
