# frozen_string_literal: true

RSpec.shared_examples 'a Geo searchable registry' do
  describe '.with_search' do
    context 'when query is empty' do
      it 'returns all registries' do
        results = described_class.with_search('')

        expect(results).to contain_exactly(registry, registry_2)
      end
    end

    context 'when query is not empty' do
      before do
        allow(described_class::MODEL_CLASS).to receive(:search).with('a super argument').and_call_original
      end

      it 'calls model_class search method' do
        expect(described_class::MODEL_CLASS).to receive(:search).with('a super argument')

        described_class.with_search('a super argument')
      end
    end
  end
end
