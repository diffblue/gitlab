# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::CreateIterableTriggerWorker, type: :worker, feature_category: :onboarding do
  describe '#perform' do
    let(:iterable_params) { { 'glm_source' => 'gitlab.com', 'provider' => 'gitlab', 'opt_in' => 'false' } }
    let(:service) { instance_double(::Onboarding::CreateIterableTriggerService) }
    let(:logger) { described_class.new.send(:logger) }
    let(:job_args) { [iterable_params] }

    before do
      allow_next_instance_of(::Onboarding::CreateIterableTriggerService) do |instance|
        allow(instance).to receive(:execute).with(iterable_params).and_return(result)
      end
    end

    context 'when request is successful' do
      let(:result) { ServiceResponse.success }

      include_examples 'an idempotent worker' do
        it 'executes successfully' do
          expect(logger).not_to receive(:error)

          expect { described_class.new.perform(*job_args) }.not_to raise_error
        end
      end
    end

    context 'when request is not successful' do
      let(:result) { ServiceResponse.error(message: '_some_error_') }

      let(:log_params) do
        {
          class: described_class.name,
          message: result.errors,
          params: { iterable_params: iterable_params }
        }
      end

      it 'has an error' do
        expect(logger).to receive(:error).with(hash_including(log_params.stringify_keys)).and_call_original

        expect { described_class.new.perform(*job_args) }.to raise_error(described_class::CreateIterableTriggerError)
      end
    end
  end
end
