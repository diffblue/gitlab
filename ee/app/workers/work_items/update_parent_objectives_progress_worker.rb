# frozen_string_literal: true

module WorkItems
  class UpdateParentObjectivesProgressWorker
    include ApplicationWorker

    data_consistency :sticky
    loggable_arguments 0
    idempotent!
    deduplicate :until_executing, ttl: 5.minutes
    urgency :high
    feature_category :team_planning

    def perform(id)
      work_item = ::WorkItem.id_in(id).first
      parent = work_item&.work_item_parent
      return unless parent && parent.work_item_type.widgets.include?(WorkItems::Widgets::Progress)

      ApplicationRecord.transaction do
        update_parent_progress(parent)
      end
    end

    private

    def update_parent_progress(parent)
      parent_progress = parent.progress || parent.build_progress
      parent_progress.lock!
      new_progress = parent.average_progress_of_children
      parent_progress.progress = new_progress

      # In the followup MR we will write to current_value instead of progress and
      # calculate progress based on start, end, and current value.
      # Issue - https://gitlab.com/gitlab-org/incubation-engineering/okr/meta/-/issues/33
      parent_progress.current_value = new_progress
      return unless parent_progress.progress_changed?

      parent_progress.save!
      ::SystemNoteService.change_progress_note(parent, User.automation_bot)
    end
  end
end
