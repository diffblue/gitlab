# frozen_string_literal: true

FactoryBot.define do
  factory :remote_development_agent_config, class: 'RemoteDevelopment::RemoteDevelopmentAgentConfig' do
    agent factory: :cluster_agent
    enabled { true }
    # noinspection RubyResolve
    dns_zone { 'workspaces.localdev.me' }
  end
end
