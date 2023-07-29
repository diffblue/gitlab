# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RemoteDevelopment::AgentConfig::Updater, feature_category: :remote_development do
  include ResultMatchers

  let(:enabled) { true }
  let(:dns_zone) { 'my-awesome-domain.me' }
  let(:network_policy_present) { false }
  let(:network_policy_enabled) { true }
  let(:network_policy) do
    { enabled: network_policy_enabled }
  end

  let(:gitlab_workspaces_proxy_present) { false }
  let(:gitlab_workspaces_proxy_namespace) { 'gitlab-workspaces' }
  let(:gitlab_workspaces_proxy) do
    { namespace: gitlab_workspaces_proxy_namespace }
  end

  let_it_be(:agent) { create(:cluster_agent) }

  let(:config) do
    remote_development_config = {
      enabled: enabled,
      dns_zone: dns_zone
    }
    remote_development_config[:network_policy] = network_policy if network_policy_present
    remote_development_config[:gitlab_workspaces_proxy] = gitlab_workspaces_proxy if gitlab_workspaces_proxy_present
    {
      remote_development: remote_development_config
    }
  end

  subject(:result) do
    described_class.update(agent: agent, config: config) # rubocop:disable Rails/SaveBang - this isn't ActiveRecord
  end

  context 'when config passed is empty' do
    let(:config) { {} }

    it "does not update and returns an ok Result containing a hash indicating update was skipped" do
      expect { subject }.to not_change { RemoteDevelopment::RemoteDevelopmentAgentConfig.count }

      expect(result)
        .to be_ok_result(RemoteDevelopment::Messages::AgentConfigUpdateSkippedBecauseNoConfigFileEntryFound.new(
          { skipped_reason: :no_config_file_entry_found }
        ))
    end
  end

  context 'when config passed is not empty' do
    context 'when a config file is valid' do
      it 'creates a config record and returns an ok Result containing the agent config' do
        expect { subject }.to change { RemoteDevelopment::RemoteDevelopmentAgentConfig.count }

        config_instance = agent.reload.remote_development_agent_config
        expect(config_instance.enabled).to eq(enabled)
        expect(config_instance.dns_zone).to eq(dns_zone)
        expect(config_instance.network_policy_enabled).to eq(network_policy_enabled)
        expect(config_instance.gitlab_workspaces_proxy_namespace).to eq(gitlab_workspaces_proxy_namespace)

        expect(result)
          .to be_ok_result(RemoteDevelopment::Messages::AgentConfigUpdateSuccessful.new(
            { remote_development_agent_config: config_instance }
          ))
      end

      context 'when network_policy key is present in the config passed' do
        let(:network_policy_present) { true }

        context 'when network_policy key is empty hash in the config passed' do
          let(:network_policy) { {} }

          it 'creates a config record with default value and returns an ok Result containing the agent config' do
            expect { subject }.to change { RemoteDevelopment::RemoteDevelopmentAgentConfig.count }

            config_instance = agent.reload.remote_development_agent_config
            expect(config_instance.enabled).to eq(enabled)
            expect(config_instance.dns_zone).to eq(dns_zone)
            expect(config_instance.network_policy_enabled).to eq(network_policy_enabled)
            expect(config_instance.gitlab_workspaces_proxy_namespace).to eq(gitlab_workspaces_proxy_namespace)

            expect(result)
              .to be_ok_result(RemoteDevelopment::Messages::AgentConfigUpdateSuccessful.new(
                { remote_development_agent_config: config_instance }
              ))
          end
        end

        context 'when network_policy.enabled is explicitly specified in the config passed' do
          let(:network_policy_enabled) { false }

          it 'creates a config record with specified value and returns an ok Result containing the agent config' do
            expect { subject }.to change { RemoteDevelopment::RemoteDevelopmentAgentConfig.count }

            config_instance = agent.reload.remote_development_agent_config
            expect(config_instance.enabled).to eq(enabled)
            expect(config_instance.dns_zone).to eq(dns_zone)
            expect(config_instance.network_policy_enabled).to eq(network_policy_enabled)
            expect(config_instance.gitlab_workspaces_proxy_namespace).to eq(gitlab_workspaces_proxy_namespace)

            expect(result)
              .to be_ok_result(RemoteDevelopment::Messages::AgentConfigUpdateSuccessful.new(
                { remote_development_agent_config: config_instance }
              ))
          end
        end
      end

      context 'when gitlab_workspaces_proxy is present in the config passed' do
        let(:gitlab_workspaces_proxy_present) { true }

        context 'when gitlab_workspaces_proxy is empty hash in the config passed' do
          let(:gitlab_workspaces_proxy) { {} }

          it 'creates a config record with default value and returns an ok Result containing the agent config' do
            expect { subject }.to change { RemoteDevelopment::RemoteDevelopmentAgentConfig.count }

            config_instance = agent.reload.remote_development_agent_config
            expect(config_instance.enabled).to eq(enabled)
            expect(config_instance.dns_zone).to eq(dns_zone)
            expect(config_instance.network_policy_enabled).to eq(network_policy_enabled)
            expect(config_instance.gitlab_workspaces_proxy_namespace).to eq(gitlab_workspaces_proxy_namespace)

            expect(result)
              .to be_ok_result(RemoteDevelopment::Messages::AgentConfigUpdateSuccessful.new(
                { remote_development_agent_config: config_instance }
              ))
          end
        end

        context 'when gitlab_workspaces_proxy.namespace is explicitly specified in the config passed' do
          let(:gitlab_workspaces_proxy_namespace) { 'gitlab-workspaces-specified' }

          it 'creates a config record with specified value and returns an ok Result containing the agent config' do
            expect { subject }.to change { RemoteDevelopment::RemoteDevelopmentAgentConfig.count }

            config_instance = agent.reload.remote_development_agent_config
            expect(config_instance.enabled).to eq(enabled)
            expect(config_instance.dns_zone).to eq(dns_zone)
            expect(config_instance.network_policy_enabled).to eq(network_policy_enabled)
            expect(config_instance.gitlab_workspaces_proxy_namespace).to eq(gitlab_workspaces_proxy_namespace)

            expect(result)
              .to be_ok_result(RemoteDevelopment::Messages::AgentConfigUpdateSuccessful.new(
                { remote_development_agent_config: config_instance }
              ))
          end
        end
      end
    end

    context 'when config file is invalid' do
      context 'when enabled is invalid' do
        let(:enabled) { false }

        it 'does not create the record and returns error' do
          expect { subject }.to not_change { RemoteDevelopment::RemoteDevelopmentAgentConfig.count }
          expect(agent.reload.remote_development_agent_config).to be_nil

          expect(result).to be_err_result do |message|
            expect(message).to be_a(RemoteDevelopment::Messages::AgentConfigUpdateFailed)
            message.context => { errors: ActiveModel::Errors => errors }
            expect(errors.full_messages.join(', ')).to match(/is currently immutable/i)
          end
        end
      end

      context 'when dns_zone is invalid' do
        let(:dns_zone) { "invalid dns zone" }

        it 'does not create the record and returns error' do
          expect { subject }.to not_change { RemoteDevelopment::RemoteDevelopmentAgentConfig.count }
          expect(agent.reload.remote_development_agent_config).to be_nil

          expect(result).to be_err_result do |message|
            expect(message).to be_a(RemoteDevelopment::Messages::AgentConfigUpdateFailed)
            message.context => { errors: ActiveModel::Errors => errors }
            expect(errors.full_messages.join(', ')).to match(/dns zone/i)
          end
        end
      end
    end
  end
end
