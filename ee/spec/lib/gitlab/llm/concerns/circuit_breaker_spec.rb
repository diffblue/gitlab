# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Concerns::CircuitBreaker, :clean_gitlab_redis_rate_limiting, feature_category: :shared do
  let(:dummy_class) do
    Class.new do
      include ::Gitlab::Llm::Concerns::CircuitBreaker

      def dummy_method
        run_with_circuit do
          raise Gitlab::Llm::Concerns::CircuitBreaker::InternalServerError
        end
      end

      def another_dummy_method
        run_with_circuit do
          # Do nothing but successful.
        end
      end
    end
  end

  subject { dummy_class.new }

  before do
    stub_const('DummyService', dummy_class)
  end

  describe '#circuit' do
    it 'returns nil value' do
      expect(Circuitbox).to receive(:circuit).with('DummyService', anything).and_call_original
      expect(subject.dummy_method).to be_nil
    end

    it 'does not raise an error' do
      expect(Circuitbox).to receive(:circuit).with('DummyService', anything).and_call_original
      expect { subject.dummy_method }.not_to raise_error
    end

    context 'when failed multiple times below volume threshold' do
      it 'does not open the circuit' do
        (described_class::VOLUME_THRESHOLD - 1).times.each do
          subject.dummy_method
        end

        expect(subject.circuit).not_to be_open
      end
    end

    context 'when failed multiple times over volume threshold' do
      it 'opens the circuit' do
        (described_class::VOLUME_THRESHOLD + 1).times.each do
          subject.dummy_method
        end

        expect(subject.circuit).to be_open
      end
    end

    context 'when circuit is previously open' do
      before do
        # Opens the circuit
        (described_class::VOLUME_THRESHOLD + 1).times.each do
          subject.dummy_method
        end

        # Deletes the open key
        subject.circuit.try_close_next_time
      end

      context 'when does not fail again' do
        it 'closes the circuit' do
          subject.another_dummy_method

          expect(subject.circuit).not_to be_open
        end
      end

      context 'when fails again' do
        it 'opens the circuit' do
          subject.dummy_method

          expect(subject.circuit).to be_open
        end
      end
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
end
