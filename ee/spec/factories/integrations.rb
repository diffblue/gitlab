# frozen_string_literal: true

FactoryBot.define do
  factory :gitlab_slack_application_integration, class: 'Integrations::GitlabSlackApplication' do
    project
    active { true }
    type { 'Integrations::GitlabSlackApplication' }
  end

  factory :github_integration, class: 'Integrations::Github' do
    project
    type { 'Integrations::Github' }
    active { true }
    token { 'github-token' }
  end
end
