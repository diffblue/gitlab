# frozen_string_literal: true

FactoryBot.define do
  factory :github_integration, class: 'Integrations::Github' do
    project
    type { 'Integrations::Github' }
    active { true }
    token { 'github-token' }
  end
end
