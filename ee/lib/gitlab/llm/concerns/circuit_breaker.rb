# frozen_string_literal: true

module Gitlab
  module Llm
    module Concerns
      module CircuitBreaker
        extend ActiveSupport::Concern

        InternalServerError = Class.new(StandardError)

        ERROR_THRESHOLD = 50
        VOLUME_THRESHOLD = 10

        included do
          def circuit
            @circuit ||= Circuitbox.circuit(service_name, {
              exceptions: [InternalServerError],
              error_threshold: ERROR_THRESHOLD,
              volume_threshold: VOLUME_THRESHOLD
            })
          end
        end

        def run_with_circuit(&block)
          circuit.run(exception: false, &block)
        end

        private

        def service_name
          raise NotImplementedError
        end
      end
    end
  end
end
