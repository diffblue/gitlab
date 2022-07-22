# frozen_string_literal: true

module Epics
  class ReopenService < Epics::BaseService
    def execute(epic)
      return epic unless can?(current_user, :update_epic, epic)

      reopen_epic(epic)
    end

    private

    def reopen_epic(epic)
      if epic.reopen
        event_service.reopen_epic(epic, current_user)
        SystemNoteService.change_status(epic, nil, current_user, epic.state)
        notification_service.reopen_epic(epic, current_user)
        ::Gitlab::UsageDataCounters::EpicActivityUniqueCounter.track_epic_reopened_action(
          author: current_user,
          namespace: epic.group
        )
      end
    end
  end
end
