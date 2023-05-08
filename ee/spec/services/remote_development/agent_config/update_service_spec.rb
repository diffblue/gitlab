# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteDevelopment::AgentConfig::UpdateService, feature_category: :remote_development do
  let(:agent) { instance_double(Clusters::Agent) }
  let(:config) { instance_double(Hash) }

  subject do
    described_class.new.execute(agent: agent, config: config)
  end

  context 'when update is successful' do
    let(:payload) { instance_double(Hash) }

    it 'returns the payload' do
      allow_next_instance_of(RemoteDevelopment::AgentConfig::UpdateProcessor) do |processor|
        expect(processor).to receive(:process).with(agent: agent, config: config).and_return([payload, nil])
      end
      expect(subject).to eq(payload)
    end
  end

  context 'when update fails' do
    let(:message) { 'error message' }
    let(:reason) { :bad_request }
    let(:error) { RemoteDevelopment::Error.new(message: message, reason: reason) }

    it 'returns false' do
      allow_next_instance_of(RemoteDevelopment::AgentConfig::UpdateProcessor) do |processor|
        expect(processor).to receive(:process).with(agent: agent, config: config).and_return([nil, error])
      end
      expect(subject).to be false
    end
  end
end
