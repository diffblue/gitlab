# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Utils::TextProcessing, feature_category: :duo_chat do
  describe '.cleanup_text' do
    context 'when stop word is present' do
      it 'returns test upto the default stop word' do
        text = 'Foo Observation: Bar'

        expect(described_class.text_before_stop_word(text)).to eq('Foo ')
      end
    end

    context 'when default stop word is missing' do
      it 'returns text unchanged' do
        text = 'Foo Bar'

        expect(described_class.text_before_stop_word(text)).to eq('Foo Bar')
      end
    end

    context 'when custom stop word is passed' do
      it 'returns text upto the default stop word' do
        text = 'Foo Question: Observation?'

        expect(described_class.text_before_stop_word(text, /Question:/)).to eq('Foo ')
      end

      context 'when custom stop word is missing from text' do
        it 'returns text unchanged' do
          text = 'Foo Observation: some text'

          expect(described_class.text_before_stop_word(text, /Question:/)).to eq('Foo Observation: some text')
        end
      end
    end
  end
end
