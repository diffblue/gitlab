# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RemoteDevelopment::AgentConfig::UpdateProcessor, feature_category: :remote_development do
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

  describe '#process' do
    subject(:results) do
      described_class.new.process(agent: agent, config: config)
    end

    context 'when config passed is empty' do
      let(:config) { {} }

      it { is_expected.to match_array([nil, nil]) }

      it 'does not create a config record' do
        expect { subject }.to not_change { RemoteDevelopment::RemoteDevelopmentAgentConfig.count }
        expect(subject[0]).to be_nil
        expect(subject[1]).to be_nil
      end
    end

    context 'when config passed is not empty' do
      it do
        is_expected.to eq(
          [
            { remote_development_agent_config: agent.reload.remote_development_agent_config },
            nil
          ]
        )
      end

      it 'creates a config record' do
        subject

        config_instance = agent.reload.remote_development_agent_config
        expect(config_instance.enabled).to eq(enabled)
        expect(config_instance.dns_zone).to eq(dns_zone)
      end
    end

    context 'when config record cannot be created' do
      context 'when enabled is not valid' do
        let(:enabled) { false }

        it 'does not create the record and returns error' do
          result = subject

          expect(result[0]).to be_nil
          expect(result[1].message).to match(/Error\(s\) updating RemoteDevelopmentAgentConfig.*is currently immutable/)
          expect(result[1].reason).to eq(:bad_request)

          config_instance = agent.reload.remote_development_agent_config
          expect(config_instance).to be_nil
        end
      end
    end
  end
end
