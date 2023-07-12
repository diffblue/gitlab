# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::AgentConfig::UpdateService, feature_category: :remote_development do
  let(:agent) { instance_double(Clusters::Agent) }
  let(:config) { instance_double(Hash) }
  let(:agent_config) { instance_double(RemoteDevelopment::RemoteDevelopmentAgentConfig) }
  let(:licensed) { true }

  subject(:service_response) do
    described_class.new.execute(agent: agent, config: config)
  end

  before do
    allow(RemoteDevelopment::AgentConfig::Main)
      .to receive(:main).with(agent: agent, config: config).and_return(response_hash)
  end

  context 'when success' do
    let(:response_hash) { { status: :success, payload: { remote_development_agent_config: agent_config } } }

    it 'returns a success ServiceResponse' do
      expect(service_response).to be_success
      expect(service_response.payload.fetch(:remote_development_agent_config)).to eq(agent_config)
    end
  end

  context 'when error' do
    let(:response_hash) { { status: :error, message: 'error', reason: :bad_request } }

    it 'returns an error success ServiceResponse' do
      expect(service_response).to be_error
      service_response => { message:, reason: }
      expect(message).to eq('error')
      expect(reason).to eq(:bad_request)
    end
  end
end
