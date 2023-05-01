# frozen_string_literal: true

module Analytics
  module ValueStreamDashboard
    class Count < ApplicationRecord
      include PartitionedTable

      self.table_name = :value_stream_dashboard_counts
      self.primary_key = :id

      partitioned_by :recorded_at, strategy: :monthly

      belongs_to :namespace

      validates :namespace_id, :count, :metric, :recorded_at, presence: true

      enum metric: {
        projects: 1,
        issues: 2,
        groups: 3,
        merge_requests: 4,
        pipelines: 5,
        members: 6
      }
    end
  end
end
