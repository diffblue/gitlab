# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RemoteDevelopment::AgentConfig::Main, "Integration", feature_category: :remote_development do
  let(:enabled) { true }
  let(:dns_zone) { 'my-awesome-domain.me' }
  let_it_be(:agent) { create(:cluster_agent) }

  let(:config) do
    {
      remote_development: {
        enabled: enabled,
        dns_zone: dns_zone
      }
    }
  end

  let(:value) { { agent: agent, config: config } }

  subject(:response) do
    described_class.main(value)
  end

  before do
    allow(License).to receive(:feature_available?).with(:remote_development).and_return(true)
  end

  context 'when config passed is empty' do
    let(:config) { {} }

    it 'does not create a config record' do
      expect { subject }.to not_change { RemoteDevelopment::RemoteDevelopmentAgentConfig.count }

      expect(response).to eq({
        status: :success,
        payload: { skipped_reason: :no_config_file_entry_found }
      })
    end
  end

  context 'when config passed is not empty' do
    it 'creates a config record' do
      expect(response).to eq({
        status: :success,
        payload: { remote_development_agent_config: agent.reload.remote_development_agent_config }
      })
    end
  end

  context 'when config record cannot be created' do
    context 'when config is invalid' do
      let(:dns_zone) { "invalid dns zone" }

      it 'does not create the record and returns error' do
        expect(response).to eq({
          status: :error,
          message: "Agent config update failed: Dns zone contains invalid characters (valid characters: [a-z0-9\\-])",
          reason: :bad_request
        })

        config_instance = agent.reload.remote_development_agent_config
        expect(config_instance).to be_nil
      end
    end
  end
end
