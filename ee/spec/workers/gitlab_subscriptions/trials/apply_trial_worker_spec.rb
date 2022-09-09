# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::Trials::ApplyTrialWorker, type: :worker do
  describe '#perform' do
    let(:logger) { described_class.new.send(:logger) }
    let(:user) { build(:user, id: non_existing_record_id) }
    let(:trial_user) { {} }
    let(:job_args) { [user.id, trial_user] }
    let(:result) { { success: true } }

    before do
      allow_next_instance_of(GitlabSubscriptions::ApplyTrialService) do |service|
        allow(service).to receive(:execute).and_return(result)
      end
    end

    include_examples 'an idempotent worker' do
      it 'executes apply trial and is successful' do
        expect_next_instance_of(GitlabSubscriptions::ApplyTrialService) do |service|
          expect(service).to receive(:execute).with(uid: user.id, trial_user: trial_user).and_return(result)
        end

        expect(logger).not_to receive(:error)

        described_class.new.perform(*job_args)
      end
    end

    it 'executes apply trial and has an error' do
      result = { success: false, errors: '_some_error_' }
      log_params = {
        class: described_class.name,
        message: result[:errors],
        params: { uid: user.id, trial_user: trial_user }
      }

      expect_next_instance_of(GitlabSubscriptions::ApplyTrialService) do |service|
        expect(service).to receive(:execute).with(uid: user.id, trial_user: trial_user).and_return(result)
      end

      expect(logger).to receive(:error).with(hash_including(log_params.stringify_keys)).and_call_original

      expect { described_class.new.perform(*job_args) }.to raise_error(described_class::ApplyTrialError)
    end
  end
end
