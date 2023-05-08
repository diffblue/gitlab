# frozen_string_literal: true

FactoryBot.define do
  factory :ee_cluster_agent, class: 'Clusters::Agent', parent: :cluster_agent do
    trait :with_remote_development_agent_config do
      remote_development_agent_config
    end
  end
end
