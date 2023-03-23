# frozen_string_literal: true

module WorkItems
  class Progress < ApplicationRecord
    self.table_name = 'work_item_progresses'

    validates :progress, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

    belongs_to :work_item, foreign_key: 'issue_id', inverse_of: :progress

    after_commit :update_all_parent_objectives_progress

    private

    def update_all_parent_objectives_progress
      return unless work_item.project.okr_automatic_rollups_enabled?
      return unless saved_change_to_attribute?(:progress)

      if work_item.project.okr_async_automatic_rollups_enabled?
        ::WorkItems::UpdateParentObjectivesProgressWorker.perform_async(work_item.id)
      else
        parent = work_item.work_item_parent
        return unless parent && parent.work_item_type.widgets.include?(WorkItems::Widgets::Progress)

        new_progress = parent.average_progress_of_children
        parent_progress = parent.progress || parent.build_progress
        parent_progress.progress = new_progress
        return unless parent_progress.progress_changed?

        parent_progress.update!(progress: new_progress)

        # rubocop: disable CodeReuse/ServiceClass
        # This will go away once this logic goes into worker via https://gitlab.com/gitlab-org/gitlab/-/issues/388394
        ::SystemNoteService.change_progress_note(parent, User.automation_bot)
        # rubocop: enable CodeReuse/ServiceClass
      end
    end
  end
end
