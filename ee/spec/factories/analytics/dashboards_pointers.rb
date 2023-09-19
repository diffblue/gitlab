# frozen_string_literal: true

FactoryBot.define do
  factory :analytics_dashboards_pointer, class: 'Analytics::DashboardsPointer' do
    namespace
    target_project { association(:project, namespace: namespace) }

    trait :project_based do
      project
      target_project { association(:project, namespace: project.namespace) }
      namespace { nil }
    end
  end
end
