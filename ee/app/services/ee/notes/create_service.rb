# frozen_string_literal: true

module EE
  module Notes
    module CreateService
      extend ::Gitlab::Utils::Override

      private

      override :track_event
      def track_event(note, user)
        track_note_creation_usage_for_epics(user, note) if note.for_epic?

        super(note, user)
      end

      def track_note_creation_usage_for_epics(user, note)
        ::Gitlab::UsageDataCounters::EpicActivityUniqueCounter.track_epic_note_created_action(
          author: user,
          namespace: note.noteable.group
        )
      end
    end
  end
end
