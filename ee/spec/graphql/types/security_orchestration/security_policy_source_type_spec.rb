# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SecurityPolicySource'] do
  let(:source) { {} }

  it 'returns all possible types' do
    expect(described_class.possible_types).to include(
      Types::SecurityOrchestration::GroupSecurityPolicySourceType,
      Types::SecurityOrchestration::ProjectSecurityPolicySourceType
    )
  end

  describe '#resolve_type' do
    let(:source) { {} }

    subject do
      described_class.resolve_type(source, {})
    end

    context 'when source is provided for namespace' do
      let(:source) { { namespace: build(:namespace), project: nil } }

      it { is_expected.to eq(Types::SecurityOrchestration::GroupSecurityPolicySourceType) }
    end

    context 'when source is provided for project' do
      let(:source) { { project: build(:project), namespace: nil } }

      it { is_expected.to eq(Types::SecurityOrchestration::ProjectSecurityPolicySourceType) }
    end
  end
end
