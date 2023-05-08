# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe RemoteDevelopment::Workspaces::Reconcile::AgentInfo, feature_category: :remote_development do
  let(:agent_info_constructor_args) do
    {
      name: 'name',
      namespace: 'namespace',
      actual_state: ::RemoteDevelopment::Workspaces::States::RUNNING,
      deployment_resource_version: '1'
    }
  end

  let(:other) { described_class.new(**agent_info_constructor_args) }

  subject do
    described_class.new(**agent_info_constructor_args)
  end

  describe '#==' do
    context 'when objects are equal' do
      it 'returns true' do
        expect(subject).to eq(other)
      end
    end

    context 'when objects are not equal' do
      it 'returns false' do
        other.instance_variable_set(:@name, 'other_name')
        expect(subject).not_to eq(other)
      end
    end
  end
end
