### Widget Extensions

#### Telemetry

Telemetry is enabled by default in all widget extensions.

However, telemetry events are not reported until they have been marked as a "known event" with a Metric Dictionary.

If telemetry metrics are desired when adding a widget extension, it is important to also create known events.

The following steps are needed to generate these known events for a single widget:

1. Widgets should be named `Widget${CamelName}`.
    - For example: a widget for "Test Reports" should be `WidgetTestReports`
1. "Compute" the widget name slug by converting the `${CamelName}` to lower-, snake-case.
    - The above example would be `test_reports`
1. Ensure the GDK is running (`gdk start`)
1. Generate known events on the command line with the following command. Replace `test_reports` with your appropriate name slug.
    ```
    bundle exec rails generate gitlab:usage_metric_definition \
    counts.mr_widgets.i_merge_request_widget_test_reports_count_view \
    counts.mr_widgets.i_merge_request_widget_test_reports_count_full_report_clicked \
    counts.mr_widgets.i_merge_request_widget_test_reports_count_expand \
    counts.mr_widgets.i_merge_request_widget_test_reports_count_expand_success \
    counts.mr_widgets.i_merge_request_widget_test_reports_count_expand_warning \
    counts.mr_widgets.i_merge_request_widget_test_reports_count_expand_failed \
    --dir=all
    ```
1. Modify each newly generated file so that they match the existing files for MR Widget Extension telemetry.
    - You can find existing examples by doing a glob search like so: `metrics/**/*_i_merge_request_widget_*`
    - Roughly-speaking, each file should have these values:
        1. `description` = A plain English description of this value. Please see existing widget extension telemetry files for examples.
            - Keep in mind that the `expand` events also report the widget status, so there needs to be events for the `expand_success`, `expand_warning`, and `expand_failure` states, too.
        1. `product_section` = `dev`
        1. `product_stage` = `create`
        1. `product_group` = `code_review`
        1. `product_category` = `code_review`
        1. `introduced_by_url` = `'[your MR]'`
        1. `options.events` = (the event in the command from above that generated this file, like `i_merge_request_widget_test_reports_count_view`)
            - This is how the telemetry events are linked to "metrics" so this is probably one of the more important values
        1. `data_source` = `redis` OR `redis_hll` (depends on whether this is a regular counter or a unique-users counter, respectively)
        1. `data_category` = `optional`
1. Repeat the previous two steps for each of the HLL metrics. Replace `test_reports` with your appropriate name slug.
    - Note that the `:redis_hll` command fails to create multiple metrics at once. You will need to create each one, modify it with the correct values, and then move to the next one (blank metrics cause a fatal error when trying to generate the next one).
    1. `bundle exec rails generate gitlab:usage_metric_definition:redis_hll mr_widgets i_merge_request_widget_test_reports_view --class_name=RedisHLLMetric`
    1. `bundle exec rails generate gitlab:usage_metric_definition:redis_hll mr_widgets i_merge_request_widget_test_reports_full_report_clicked --class_name=RedisHLLMetric`
    1. `bundle exec rails generate gitlab:usage_metric_definition:redis_hll mr_widgets i_merge_request_widget_test_reports_expand --class_name=RedisHLLMetric`
    1. `bundle exec rails generate gitlab:usage_metric_definition:redis_hll mr_widgets i_merge_request_widget_test_reports_expand_success --class_name=RedisHLLMetric`
    1. `bundle exec rails generate gitlab:usage_metric_definition:redis_hll mr_widgets i_merge_request_widget_test_reports_expand_warning --class_name=RedisHLLMetric`
    1. `bundle exec rails generate gitlab:usage_metric_definition:redis_hll mr_widgets i_merge_request_widget_test_reports_expand_failed --class_name=RedisHLLMetric`
1. Add each of the HLL metrics to `lib/gitlab/usage_data_counters/known_events/code_review_events.yml`
    - You **MUST** do this **after** completely finishing all of the generation in the previous steps, or it will create fatal errors.
    1. `name` = [the event]
    1. `redis_slot` = `code_review`
    1. `category` = `code_review`
    1. `aggregation` = `weekly`
