# frozen_string_literal: true

class Elastic::ReindexingTask < ApplicationRecord
  include IgnorableColumns

  self.table_name = 'elastic_reindexing_tasks'

  validates :max_slices_running, presence: true
  validates :slice_multiplier, presence: true

  ignore_columns %i[documents_count index_name_from index_name_to elastic_task documents_count_target], remove_with: '14.3', remove_after: '2021-09-10'

  has_many :subtasks, class_name: 'Elastic::ReindexingSubtask', foreign_key: :elastic_reindexing_task_id

  enum state: {
    initial:                0,
    indexing_paused:        1,
    reindexing:             2,
    success:                10, # states less than 10 are considered in_progress
    failure:                11,
    original_index_deleted: 12
  }

  scope :old_indices_scheduled_for_deletion, -> { where(state: :success).where.not(delete_original_index_at: nil) }
  scope :old_indices_to_be_deleted, -> { old_indices_scheduled_for_deletion.where('delete_original_index_at < NOW()') }

  before_save :set_in_progress_flag

  def self.current
    where(in_progress: true).last
  end

  def self.running?
    current.present?
  end

  def self.drop_old_indices!
    old_indices_to_be_deleted.find_each do |task|
      task.subtasks.each do |subtask|
        Gitlab::Elastic::Helper.default.delete_index(index_name: subtask.index_name_from)
      end
      task.update!(state: :original_index_deleted)
    end
  end

  private

  def set_in_progress_flag
    in_progress_states = self.class.states.select { |_, v| v < 10 }.keys

    self.in_progress = in_progress_states.include?(state)
  end
end
