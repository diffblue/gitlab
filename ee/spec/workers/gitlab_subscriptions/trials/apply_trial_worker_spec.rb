# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::Trials::ApplyTrialWorker, type: :worker, feature_category: :purchase do
  describe '#perform' do
    let(:logger) { described_class.new.send(:logger) }
    let(:user) { build(:user, id: non_existing_record_id) }
    let(:job_args) { [user.id, trial_user_information] }

    context 'when valid to generate a trial' do
      let_it_be(:namespace) { create(:namespace) }

      let(:trial_user_information) { { 'namespace_id' => namespace.id } }

      context 'when trial is successfully applied' do
        let(:service) { instance_double(GitlabSubscriptions::Trials::ApplyTrialService) }

        before do
          allow(GitlabSubscriptions::Trials::ApplyTrialService).to receive(:new).and_return(service)
          allow(service).to receive(:execute).and_return(ServiceResponse.success)
        end

        include_examples 'an idempotent worker' do
          it 'executes apply trial and is successful' do
            expect(service).to receive(:execute).and_return(ServiceResponse.success)
            expect(logger).not_to receive(:error)

            described_class.new.perform(*job_args)
          end
        end
      end

      context 'when not successful in generating a trial' do
        let(:service) do
          instance_double(GitlabSubscriptions::Trials::ApplyTrialService, valid_to_generate_trial?: true)
        end

        let(:result) { ServiceResponse.error(message: '_some_error_') }
        let(:log_params) do
          {
            class: described_class.name,
            message: result.errors,
            params: { uid: user.id, trial_user_information: trial_user_information }
          }
        end

        before do
          allow(GitlabSubscriptions::Trials::ApplyTrialService)
            .to receive(:new)
                  .with(uid: user.id, trial_user_information: trial_user_information.deep_symbolize_keys)
                  .and_return(service)
        end

        it 'executes apply trial and has an error' do
          expect(service).to receive(:execute).and_return(result)
          expect(logger).to receive(:error).with(hash_including(log_params.stringify_keys)).and_call_original

          expect { described_class.new.perform(*job_args) }.to raise_error(described_class::ApplyTrialError)
        end
      end
    end

    context 'when not valid to generate a trial' do
      let(:log_params) do
        {
          class: described_class.name,
          message: ['Not valid to generate a trial with current information'],
          params: { uid: user.id, trial_user_information: trial_user_information }
        }
      end

      context 'without namespace_id' do
        let(:trial_user_information) { {} }

        it 'does not apply the trial and logs an error' do
          expect(logger).to receive(:error).with(hash_including(log_params.stringify_keys)).and_call_original

          expect { described_class.new.perform(*job_args) }.not_to raise_error
        end
      end

      context 'when namespace does not exist' do
        let(:trial_user_information) { { 'namespace_id' => non_existing_record_id } }

        it 'does not apply the trial and logs an error' do
          expect(logger).to receive(:error).with(hash_including(log_params.stringify_keys)).and_call_original

          expect { described_class.new.perform(*job_args) }.not_to raise_error
        end
      end
    end
  end
end
