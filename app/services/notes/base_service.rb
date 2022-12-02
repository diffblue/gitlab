# frozen_string_literal: true

module Notes
  class BaseService < ::BaseService
    WidgetNotSupported = Class.new(StandardError)

    def execute(note)
      # If this is a not on an work item(or issue), depending on the work item type it may not support notes widget.
      # This is not a breaking change as currently all work item types support notes, however this is added
      # as a precaution in case in future we add work item types without notes widget support.
      note.errors.add(:base, "Notes are not supported") unless note.noteable&.supports_notes?
    end

    def clear_noteable_diffs_cache(note)
      if note.is_a?(DiffNote) &&
          note.start_of_discussion? &&
          note.position.unfolded_diff?(project.repository)
        note.noteable.diffs.clear_cache
      end
    end

    def increment_usage_counter(note)
      Gitlab::UsageDataCounters::NoteCounter.count(:create, note.noteable_type)
    end
  end
end
