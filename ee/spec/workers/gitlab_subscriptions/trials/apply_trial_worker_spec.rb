# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::Trials::ApplyTrialWorker, type: :worker do
  describe '#perform' do
    let(:logger) { described_class.new.send(:logger) }
    let(:user) { build(:user, id: non_existing_record_id) }
    let(:trial_user_information) { {} }
    let(:job_args) { [user.id, trial_user_information] }

    include_examples 'an idempotent worker' do
      it 'executes apply trial and is successful' do
        service = instance_double(GitlabSubscriptions::ApplyTrialService)
        allow(GitlabSubscriptions::ApplyTrialService).to receive(:new).and_return(service)

        expect(service).to receive(:execute).and_return(ServiceResponse.success)
        expect(logger).not_to receive(:error)

        described_class.new.perform(*job_args)
      end
    end

    context 'when not successful in generating a trial' do
      let(:service) { instance_double(GitlabSubscriptions::ApplyTrialService, valid_to_generate_trial?: true) }
      let(:result) { ServiceResponse.error(message: '_some_error_') }
      let(:log_params) do
        {
          class: described_class.name,
          message: result.errors,
          params: { uid: user.id, trial_user_information: trial_user_information }
        }
      end

      before do
        allow(GitlabSubscriptions::ApplyTrialService).to receive(:new)
                                                           .with(uid: user.id,
                                                                 trial_user_information: trial_user_information)
                                                           .and_return(service)
      end

      it 'executes apply trial and has an error' do
        expect(service).to receive(:execute).and_return(result)
        expect(logger).to receive(:error).with(hash_including(log_params.stringify_keys)).and_call_original

        expect { described_class.new.perform(*job_args) }.to raise_error(described_class::ApplyTrialError)
      end

      context 'when not valid to generate a trial' do
        let(:service) { instance_double(GitlabSubscriptions::ApplyTrialService, valid_to_generate_trial?: false) }

        it 'executes apply trial and has an error' do
          expect(service).to receive(:execute).and_return(result)
          expect(logger).to receive(:error).with(hash_including(log_params.stringify_keys)).and_call_original

          expect { described_class.new.perform(*job_args) }.not_to raise_error
        end
      end
    end
  end
end
