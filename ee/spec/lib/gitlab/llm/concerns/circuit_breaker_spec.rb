# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Concerns::CircuitBreaker, feature_category: :shared do
  let(:dummy_class) do
    Class.new do
      include ::Gitlab::Llm::Concerns::CircuitBreaker

      def dummy_method
        run_with_circuit do
          raise Gitlab::Llm::Concerns::CircuitBreaker::InternalServerError
        end
      end

      private

      def service_name
        'dummy_service'
      end
    end
  end

  subject { dummy_class.new }

  describe '#circuit' do
    it 'returns nil value' do
      expect(Circuitbox).to receive(:circuit).with('dummy_service', anything).and_call_original
      expect(subject.dummy_method).to be_nil
    end

    it 'does not raise an error' do
      expect(Circuitbox).to receive(:circuit).with('dummy_service', anything).and_call_original
      expect { subject.dummy_method }.not_to raise_error
    end
  end

  describe '#run_with_circuit' do
    let(:circuit) { double('circuit') } # rubocop: disable RSpec/VerifiedDoubles
    let(:block) { proc {} }

    before do
      allow(subject).to receive(:circuit).and_return(circuit)
    end

    it 'runs the code block within the Circuitbox circuit' do
      expect(circuit).to receive(:run).with(exception: false, &block)
      subject.run_with_circuit(&block)
    end
  end

  describe '#service_name' do
    it 'raises NotImplementedError' do
      instance = Object.new
      instance.extend(described_class)

      expect { instance.send(:service_name) }.to raise_error(NotImplementedError)
    end
  end
end
