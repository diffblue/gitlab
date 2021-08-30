# frozen_string_literal: true

FactoryBot.define do
  factory :project_namespace, class: 'Namespaces::ProjectNamespace' do
    project
    sequence(:name) { |n| "project_namespace#{n}" }
    path { name.downcase.gsub(/\s/, '_') }
    type { 'Namespaces::ProjectNamespace' }
    owner { nil }
    project_creation_level { ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS }
  end
end
