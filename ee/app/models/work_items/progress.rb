# frozen_string_literal: true

module WorkItems
  class Progress < ApplicationRecord
    self.table_name = 'work_item_progresses'

    validates :progress, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
    validates :start_value, :current_value, :end_value, presence: true
    validate :check_start_end_values_to_not_be_same

    belongs_to :work_item, foreign_key: 'issue_id', inverse_of: :progress

    after_commit :update_all_parent_objectives_progress

    def compute_progress
      (((current_value - start_value).abs / (end_value - start_value).abs) * 100).to_i
    end

    private

    def update_all_parent_objectives_progress
      return unless work_item.project.okr_automatic_rollups_enabled?
      return unless saved_change_to_attribute?(:progress)

      ::WorkItems::UpdateParentObjectivesProgressWorker.perform_async(work_item.id)
    end

    def check_start_end_values_to_not_be_same
      errors.add(:start_value, "cannot be same as end value") if start_value == end_value
    end
  end
end
