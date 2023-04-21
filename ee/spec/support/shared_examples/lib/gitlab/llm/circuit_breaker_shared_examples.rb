# frozen_string_literal: true

RSpec.shared_examples 'has circuit breaker' do
  describe '#call_external_service' do
    it 'runs the code block within the circuit breaker' do
      expect(service).to receive(:run_with_circuit)
      subject
    end
  end
end
