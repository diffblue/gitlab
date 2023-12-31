CREATE TABLE ci_finished_builds_aggregated_queueing_delay_percentiles
(
    status LowCardinality(String) DEFAULT '',
    runner_type UInt8 DEFAULT 0,
    started_at_bucket DateTime64(6, 'UTC') DEFAULT now(),

    count_builds AggregateFunction(count),
    queueing_duration_quantile AggregateFunction(quantile, Int64)
)
ENGINE = AggregatingMergeTree()
ORDER BY (started_at_bucket, status, runner_type)
