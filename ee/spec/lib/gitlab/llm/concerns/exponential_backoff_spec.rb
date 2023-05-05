# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Concerns::ExponentialBackoff, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  let(:body) { { 'test' => 'test' } }
  let(:response) { instance_double(Net::HTTPResponse, body: body.to_json) }
  let(:success) do
    instance_double(HTTParty::Response,
      code: 200, success?: true, parsed_response: {},
      response: response, server_error?: false, too_many_requests?: false
    )
  end

  let(:too_many_requests_error) do
    instance_double(HTTParty::Response,
      code: 429, success?: false, parsed_response: {},
      response: response, server_error?: false, too_many_requests?: true
    )
  end

  let(:auth_error) do
    instance_double(HTTParty::Response,
      code: 401, success?: false, parsed_response: {},
      response: response, server_error?: false, too_many_requests?: false
    )
  end

  let(:empty_response) do
    instance_double(HTTParty::Response, response: nil)
  end

  let(:response_caller) { -> { success } }

  let(:dummy_class) do
    Class.new do
      def dummy_method(response_caller)
        response_caller.call
      end

      include Gitlab::Llm::Concerns::ExponentialBackoff
      retry_methods_with_exponential_backoff :dummy_method
    end
  end

  subject { dummy_class.new.dummy_method(response_caller) }

  it_behaves_like 'has circuit breaker' do
    let(:service) { dummy_class.new }
    let(:subject) { service.dummy_method(response_caller) }
  end

  context 'with feature flag disabled' do
    before do
      stub_feature_flags(circuit_breaker: false)
    end

    it 'runs the code block outside of the circuit breaker' do
      service = dummy_class.new
      subject = service.dummy_method(response_caller)

      expect(service).not_to receive(:run_with_circuit)
      subject
    end
  end

  describe '.wrap_method' do
    it 'wraps the instance method and retries with exponential backoff' do
      service = dummy_class.new

      expect(service).to receive(:retry_with_exponential_backoff).and_call_original
      expect(service.dummy_method(response_caller)).to be_success
    end
  end

  describe '.retry_with_exponential_backoff' do
    let(:max_retries) { described_class::MAX_RETRIES }

    context 'when the function succeeds on the first try' do
      it 'calls the function once and returns its result' do
        expect(response_caller).to receive(:call).once.and_call_original

        expect(subject).to be_success
      end
    end

    context 'when the function response is an error' do
      before do
        stub_const("#{described_class.name}::INITIAL_DELAY", 0.0)
        allow(Random).to receive(:rand).and_return(0.001)
      end

      it 'retries the function with an exponential backoff until it succeeds' do
        allow(response_caller).to receive(:call).and_return(too_many_requests_error, success)

        expect(subject).to be_success
        expect(Random).to have_received(:rand).once
        expect(response_caller).to have_received(:call).exactly(2).times
      end

      it 'raises a RateLimitError if the maximum number of retries is exceeded' do
        allow(response_caller).to receive(:call).and_return(too_many_requests_error).exactly(max_retries).times

        expect do
          subject
        end.to raise_error(described_class::RateLimitError, "Maximum number of retries (#{max_retries}) exceeded.")

        expect(response_caller).to have_received(:call).exactly(max_retries).times
      end

      context 'without rate limit error' do
        it 'returns error message' do
          allow(response_caller).to receive(:call).and_return(auth_error).once

          expect(subject).to eq(auth_error)
          expect(response_caller).to have_received(:call).once
        end
      end
    end

    context 'when the function response is empty' do
      it 'does not retry the function' do
        allow(response_caller).to receive(:call).and_return(empty_response)

        expect(subject).to be_nil
        expect(response_caller).to have_received(:call).once
      end
    end
  end
end
