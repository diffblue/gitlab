# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountSecurePipelinesMetric < DatabaseMetric
          operation :estimate_batch_distinct_count, column: :pipeline_id

          relation { ::Security::Scan }

          def initialize(metric_definition)
            super

            return if scan_types.include?(scan_type)

            raise ArgumentError, "scan_type must be present and one of: #{scan_types.join(', ')}"
          end

          def value
            aggregated_metrics_params = {
              metric_name: "#{scan_type}_pipeline",
              recorded_at_timestamp: Time.current,
              time_period: time_constraints
            }

            if start_id && finish_id
              estimate_batch_distinct_count(relation, :pipeline_id, batch_size: 1000, start: start_id,
                finish: finish_id) do |result|
                ::Gitlab::Usage::Metrics::Aggregates::Sources::PostgresHll
                  .save_aggregated_metrics(**aggregated_metrics_params.merge({ data: result }))
              end
            else

              params_merged = aggregated_metrics_params.merge({ data: ::Gitlab::Database::PostgresHll::Buckets.new })
              ::Gitlab::Usage::Metrics::Aggregates::Sources::PostgresHll
                .save_aggregated_metrics(**params_merged)
              0
            end
          end

          private

          def start_id
            outer_relation
              .select("(#{inner_relation.order(id: :asc).limit(1).to_sql})")
              .order('1 ASC NULLS LAST')
              .first&.id
          end

          def finish_id
            outer_relation
              .select("(#{inner_relation.order(id: :desc).limit(1).to_sql})")
              .order('1 DESC NULLS LAST')
              .first&.id
          end

          def relation
            super.by_scan_types(scan_type)
          end

          def scan_type
            options[:scan_type]
          end

          def scan_types
            ::Security::Scan.scan_types.except('cluster_image_scanning').keys
          end

          def inner_relation
            ::Security::Scan.select(:id)
                            .where(
                              to_date_arel_node(Arel.sql('date_range_source'))
                                .eq(to_date_arel_node(::Security::Scan.arel_table[time_constraints.keys[0]]))
                            )
          end

          def outer_relation
            ::Security::Scan
              .from("generate_series(
                                '#{time_constraints.values[0].first.to_time.to_fs(:db)}'::timestamp,
                                '#{time_constraints.values[0].last.to_time.to_fs(:db)}'::timestamp,
                                '1 day'::interval) date_range_source")
          end

          def to_date_arel_node(column)
            locked_timezone = Arel::Nodes::NamedFunction.new('TIMEZONE', [Arel.sql("'UTC'"), column])
            Arel::Nodes::NamedFunction.new('DATE', [locked_timezone])
          end
        end
      end
    end
  end
end
