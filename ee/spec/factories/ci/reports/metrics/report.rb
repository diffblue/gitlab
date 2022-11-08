# frozen_string_literal: true

FactoryBot.define do
  factory :ci_reports_metrics_report, class: '::Gitlab::Ci::Reports::Metrics::Report' do
    trait :base_metrics do
      after(:build) do |report, _|
        report.add_metric('metric_name', 'metric_value')
        report.add_metric('second_metric_name', 'metric_value')
      end
    end

    trait :head_metrics do
      after(:build) do |report, _|
        report.add_metric('metric_name', 'metric_value')
        report.add_metric('extra_metric_name', 'metric_value')
      end
    end

    skip_create
  end
end
