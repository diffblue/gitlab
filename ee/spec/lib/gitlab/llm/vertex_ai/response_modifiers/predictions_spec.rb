# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::VertexAi::ResponseModifiers::Predictions, feature_category: :ai_abstraction_layer do
  describe '#response_body' do
    subject(:response_body) { described_class.new(ai_response.to_json).response_body }

    context 'when AI response predictions has candidates' do
      let(:ai_response) { { predictions: [{ candidates: [{ content: 'response' }] }] } }

      it 'returns content' do
        expect(response_body).to eq('response')
      end
    end

    context 'when AI response predictions has no candidates' do
      let(:ai_response) { { predictions: [{ content: 'response' }] } }

      it 'returns content' do
        expect(response_body).to eq('response')
      end
    end

    context 'when AI response is nil' do
      let(:ai_response) { nil }

      it 'returns blank string' do
        expect(response_body).to be_blank
      end
    end
  end

  describe '#errors' do
    let(:ai_response) { { error: { message: 'error' } } }

    subject(:errors) { described_class.new(ai_response.to_json).errors }

    it 'returns array of errors' do
      expect(errors).to eq(['error'])
    end

    context 'when AI response is nil' do
      let(:ai_response) { nil }

      it 'returns empty array' do
        expect(errors).to be_empty
      end
    end
  end
end
