# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::ExplainCode::Executor, feature_category: :shared do
  subject(:tool) { described_class.new(context: nil, options: { input: 'input' }) }

  describe '#name' do
    it 'returns tool name' do
      expect(described_class::NAME).to eq('ExplainCode')
    end
  end

  describe '#description' do
    it 'returns tool description' do
      desc = 'Useful tool to explain code snippets.'

      expect(described_class::DESCRIPTION).to include(desc)
    end
  end

  describe '#execute' do
    context 'when context is authorized' do
      before do
        allow(Gitlab::Llm::Chain::Utils::Authorizer).to receive(:context_authorized?).and_return(true)
      end

      context 'when response is successful' do
        it 'returns success answer' do
          allow(tool).to receive(:request).and_return('response')

          expect(tool.execute.content).to eq('response')
        end
      end

      context 'when error is raised during a request' do
        it 'returns error answer' do
          allow(tool).to receive(:request).and_raise(StandardError)

          expect(tool.execute.content).to eq('Unexpected error')
        end
      end
    end

    context 'when context is not authorized' do
      before do
        allow(Gitlab::Llm::Chain::Utils::Authorizer).to receive(:context_authorized?).and_return(false)
      end

      it 'returns error answer' do
        allow(tool).to receive(:authorize).and_return(false)

        expect(tool.execute.content)
          .to eq('I am sorry, I am unable to find the explain code answer you are looking for.')
      end
    end
  end
end
