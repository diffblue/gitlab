# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Llm, feature_category: :ai_abstraction_layer do
  describe '#initialize_slis!' do
    it 'initializes Apdex SLIs for Llm' do
      expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli).with(
        :llm_chat_answers,
        a_kind_of(Array)
      )
      expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli).with(
        :llm_client_request,
        a_kind_of(Array)
      )

      described_class.initialize_slis!
    end
  end
end
