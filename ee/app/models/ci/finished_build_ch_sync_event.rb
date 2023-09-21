# frozen_string_literal: true

module Ci
  class FinishedBuildChSyncEvent < Ci::ApplicationRecord
    PARTITION_DURATION = 1.day

    include PartitionedTable

    self.table_name = :p_ci_finished_build_ch_sync_events
    self.primary_key = :build_id
    self.ignored_columns = %i[partition] # rubocop: disable Cop/IgnoredColumns

    partitioned_by :partition, strategy: :sliding_list,
      next_partition_if: ->(active_partition) do
        oldest_record_in_partition = FinishedBuildChSyncEvent.for_partition(active_partition.value).first

        oldest_record_in_partition.present? &&
          oldest_record_in_partition.build_finished_at < PARTITION_DURATION.ago
      end,
      detach_partition_if: ->(partition) do
        !FinishedBuildChSyncEvent.pending.for_partition(partition.value).exists?
      end

    validates :build_id, presence: true
    validates :build_finished_at, presence: true

    scope :pending, -> { where(processed: false) }
    scope :for_partition, ->(partition) { where(partition: partition) }
  end
end
