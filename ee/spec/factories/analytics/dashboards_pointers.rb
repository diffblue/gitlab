# frozen_string_literal: true

FactoryBot.define do
  factory :analytics_dashboards_pointer, class: 'Analytics::DashboardsPointer' do
    namespace
    target_project factory: :project

    trait :project_based do
      project
      namespace { nil }
    end
  end
end
