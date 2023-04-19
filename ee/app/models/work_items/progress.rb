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

      ::WorkItems::UpdateParentObjectivesProgressWorker.perform_async(work_item.id)
    end
  end
end
