# frozen_string_literal: true

RSpec.shared_examples 'a Geo searchable registry' do
  let(:registry_class_factory) { described_class.underscore.tr('/', '_').to_sym }

  describe '.with_search' do
    context 'when query is empty' do
      it 'returns all registries' do
        # rubocop:disable Rails/SaveBang
        registry_1 = create(registry_class_factory)
        registry_2 = create(registry_class_factory)
        # rubocop:enable Rails/SaveBang

        results = described_class.with_search('')

        expect(results).to contain_exactly(registry_1, registry_2)
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
