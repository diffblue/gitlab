# frozen_string_literal: true

module Analytics
  module ValueStreamDashboard
    class Aggregation < ApplicationRecord
      self.table_name = :value_stream_dashboard_aggregations

      belongs_to :namespace, optional: false

      validates_inclusion_of :enabled, in: [true, false]
      validates_presence_of :namespace_id
    end
  end
end
