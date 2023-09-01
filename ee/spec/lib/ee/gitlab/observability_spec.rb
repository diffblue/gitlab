# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Observability, feature_category: :tracing do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  describe '.tracing_enabled?' do
    subject(:tracing_enabled) { described_class.tracing_enabled?(project) }

    it 'returns false if unlicensed' do
      expect(tracing_enabled).to be(false)
    end

    context 'when licensed' do
      before do
        stub_licensed_features(tracing: true)
      end

      it 'returns true if feature is enabled globally' do
        expect(tracing_enabled).to be(true)
      end

      it 'returns true if feature is enabled for the project' do
        stub_feature_flags(observability_tracing: false)
        stub_feature_flags(observability_tracing: project)

        expect(tracing_enabled).to be(true)
      end

      it 'returns false if feature is disabled globally' do
        stub_feature_flags(observability_tracing: false)

        expect(tracing_enabled).to be(false)
      end
    end
  end

  describe '.tracing_url' do
    subject { described_class.tracing_url(project) }

    it { is_expected.to eq("#{described_class.observability_url}/query/#{group.id}/#{project.id}/v1/traces") }
  end
end
