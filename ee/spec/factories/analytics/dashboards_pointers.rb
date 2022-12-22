# frozen_string_literal: true

FactoryBot.define do
  factory :analytics_dashboards_pointer, class: 'Analytics::DashboardsPointer' do
    namespace
    project
  end
end
