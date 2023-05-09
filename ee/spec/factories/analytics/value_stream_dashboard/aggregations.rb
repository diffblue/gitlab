# frozen_string_literal: true

FactoryBot.define do
  factory :value_stream_dashboard_aggregation, class: 'Analytics::ValueStreamDashboard::Aggregation' do
    namespace { association(:group) }
    enabled { true }
    last_run_at { Time.now }
  end
end
