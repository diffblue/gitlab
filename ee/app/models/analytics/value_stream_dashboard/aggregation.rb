# frozen_string_literal: true

module Analytics
  module ValueStreamDashboard
    class Aggregation < ApplicationRecord
      include FromUnion

      self.table_name = :value_stream_dashboard_aggregations

      belongs_to :namespace, optional: false

      validates_inclusion_of :enabled, in: [true, false]
      validates_presence_of :namespace_id

      scope :latest_first_order, -> { order(arel_table[:last_run_at].asc.nulls_first, arel_table[:namespace_id].asc) }
      scope :outdated, -> { where('last_run_at < ?', 10.days.ago) }
      scope :enabled, -> { where('enabled IS TRUE') }
      scope :not_aggregated, -> { where(last_run_at: nil) }
      # ensures that a given namespace_id will show up as the first result
      scope :specific_namespace_id_first_order, ->(namespace_id) {
        order(arel_table[:namespace_id].not_eq(namespace_id))
      }

      def self.load_batch(cursor = nil, batch_size = 100)
        top_level_namespace_id = cursor && cursor[:top_level_namespace_id]

        unions = [
          enabled.not_aggregated.latest_first_order.limit(batch_size),
          enabled.outdated.latest_first_order.limit(batch_size)
        ].compact

        unions.unshift(primary_key_in(top_level_namespace_id)) if top_level_namespace_id

        query = from_union(unions, remove_order: false)
        query = query.specific_namespace_id_first_order(top_level_namespace_id) if top_level_namespace_id

        query.latest_first_order.limit(batch_size).to_a
      end
    end
  end
end
