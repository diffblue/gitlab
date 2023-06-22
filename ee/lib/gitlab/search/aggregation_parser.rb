# frozen_string_literal: true

module Gitlab
  module Search
    class AggregationParser
      class << self
        def call(aggregations)
          return [] unless aggregations

          aggregations.keys.map do |key|
            buckets = aggregations[key].buckets

            buckets = add_extra_data_for_labels(buckets) if key == 'labels'

            ::Gitlab::Search::Aggregation.new(key, buckets)
          end
        end

        private

        def add_extra_data_for_labels(buckets)
          labels = Label.id_in(buckets.map { |m| m['key'].to_i })
          labels_hash = labels.index_by(&:id)
          projects_hash = Project.inc_routes.find(labels.map(&:project_id).compact).index_by(&:id)
          groups_hash = Group.include_route.find(labels.map(&:group_id).compact).index_by(&:id)

          buckets.filter_map do |bucket|
            label_id_key = bucket['key'].to_i
            label = labels_hash[label_id_key]
            if label
              project_name = projects_hash[label.project_id]&.full_name
              group_name = groups_hash[label.group_id]&.full_name

              bucket['extra'] = {
                title: label.title,
                color: label.color.to_s,
                type: label.type,
                parent_full_name: project_name || group_name
              }

              bucket
            end
          end
        end
      end
    end
  end
end
