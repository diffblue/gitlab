# frozen_string_literal: true

FactoryBot.define do
  factory :ci_subscriptions_project, class: 'Ci::Subscriptions::Project' do
    downstream_project factory: :project
    upstream_project factory: [:project, :public]
    author factory: :user
  end
end
