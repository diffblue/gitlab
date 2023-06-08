# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Chain::Tools::Tool, feature_category: :shared do
  let(:context) { instance_double(Gitlab::Llm::Chain::GitlabContext) }
  let(:options) { {} }

  subject { described_class.new(context: context, options: options) }

  describe '#execute' do
    context 'when authorize returns true' do
      before do
        allow(subject).to receive(:authorize).and_return(true)
        allow(subject).to receive(:perform)
      end

      it 'calls perform' do
        expect(subject).to receive(:perform)
        subject.execute
      end
    end

    context 'when authorize returns false' do
      before do
        allow(subject).to receive(:authorize).and_return(false)
        allow(subject).to receive(:not_found)
      end

      it 'calls not_found' do
        expect(subject).to receive(:not_found)
        subject.execute
      end
    end
  end

  describe '#authorize' do
    it 'raises NotImplementedError' do
      expect { subject.authorize }.to raise_error(NotImplementedError)
    end
  end

  describe '#perform' do
    it 'raises NotImplementedError' do
      expect { subject.perform }.to raise_error(NotImplementedError)
    end
  end
end
