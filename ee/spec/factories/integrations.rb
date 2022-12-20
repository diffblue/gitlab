# frozen_string_literal: true

FactoryBot.define do
  factory :gitlab_slack_application_integration, class: 'Integrations::GitlabSlackApplication' do
    project
    active { true }
    type { 'Integrations::GitlabSlackApplication' }
    slack_integration { association :slack_integration, integration: instance }

    transient do
      all_channels { true }
    end

    after(:build) do |integration, evaluator|
      next unless evaluator.all_channels

      integration.event_channel_names.each do |name|
        integration.send("#{name}=".to_sym, "##{name}")
      end
    end

    trait :all_features_supported do
      slack_integration { association :slack_integration, :all_features_supported, integration: instance }
    end
  end

  factory :github_integration, class: 'Integrations::Github' do
    project
    type { 'Integrations::Github' }
    active { true }
    token { 'github-token' }
  end
end
