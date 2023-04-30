# frozen_string_literal: true

FactoryBot.define do
  factory :value_stream_dashboard_count, class: 'Analytics::ValueStreamDashboard::Count' do
    recorded_at { Time.now }
    metric { :projects }
    count { 1_000 }
    namespace { association(:group) }
  end
end
