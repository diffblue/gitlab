# frozen_string_literal: true

module EE
  module EventsHelper
    extend ::Gitlab::Utils::Override

    override :event_note_target_url
    def event_note_target_url(event)
      if event.epic_note?
        group_epic_url(event.group, event.note_target, anchor: dom_id(event.target))
      elsif event.vulnerability_note?
        project_security_vulnerability_url(event.project, event.note_target, anchor: dom_id(event.target))
      else
        super
      end
    end
  end
end
