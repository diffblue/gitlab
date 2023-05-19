# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Utils::TextProcessing, feature_category: :shared do
  describe '.cleanup_text' do
    context 'when stop word is present' do
      it 'returns test upto the stop word' do
        text = 'Foo Observation: Bar'

        expect(described_class.text_before_stop_word(text)).to eq('Foo ')
      end
    end

    context 'when stop word is missing' do
      it 'returns text unchanged' do
        text = 'Foo Bar'

        expect(described_class.text_before_stop_word(text)).to eq('Foo Bar')
      end
    end
  end
end
