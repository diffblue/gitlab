# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Llm, feature_category: :ai_abstraction_layer do
  describe '#initialize_slis!' do
    it 'initializes Apdex SLIs for Llm' do
      expect(Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli).with(
        :llm_completion,
        a_kind_of(Array)
      )
      expect(Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli).with(
        :llm_client_request,
        a_kind_of(Array)
      )
      expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli).with(
        :llm_completion,
        a_kind_of(Array)
      )

      described_class.initialize_slis!
    end
  end

  describe '#client_label' do
    it 'returns client label for known clients class' do
      expect(described_class.client_label(Gitlab::Llm::VertexAi::Client)).to eq(:vertex_ai)
      expect(described_class.client_label(Gitlab::Llm::Anthropic::Client)).to eq(:anthropic)
      expect(described_class.client_label(Gitlab::Llm::OpenAi::Client)).to eq(:open_ai)
    end

    it 'returns :unknwon for other classes' do
      expect(described_class.client_label(Gitlab::Llm::ChatStorage)).to eq(:unknown)
    end
  end
end
