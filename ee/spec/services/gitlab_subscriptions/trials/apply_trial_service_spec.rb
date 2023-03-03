# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::Trials::ApplyTrialService, feature_category: :billing_and_payments do
  let_it_be(:namespace) { create(:namespace) }

  let(:user) { namespace.owner }
  let(:trial_user_information) { { namespace_id: namespace.id } }
  let(:apply_trial_params) do
    {
      uid: user.id,
      trial_user_information: trial_user_information
    }
  end

  describe '.execute' do
    before do
      allow(Gitlab::SubscriptionPortal::Client).to receive(:generate_trial).and_return(response)
    end

    subject(:execute) { described_class.execute(**apply_trial_params) }

    context 'when trial is applied successfully' do
      let(:response) { { success: true } }

      it 'returns success: true' do
        expect(execute).to be_success
      end

      it_behaves_like 'records an onboarding progress action', :trial_started
    end
  end

  describe '#execute' do
    subject(:execute) { described_class.new(**apply_trial_params).execute }

    context 'when valid to generate a trial' do
      before do
        allow(Gitlab::SubscriptionPortal::Client).to receive(:generate_trial).and_return(response)
      end

      context 'when trial is applied successfully' do
        let(:response) { { success: true } }

        it 'returns success: true' do
          expect(execute).to be_success
        end

        it_behaves_like 'records an onboarding progress action', :trial_started
      end

      context 'with error while applying the trial' do
        let(:response) { { success: false, data: { errors: ['some error'] } } }

        it 'returns success: false with errors' do
          expect(execute).to be_error.and have_attributes(message: ['some error'])
        end

        it_behaves_like 'does not record an onboarding progress action'
      end
    end

    context 'when not valid to generate a trial' do
      context 'when namespace_id is not in the trial_user_information' do
        let(:trial_user_information) { {} }

        it 'returns success: false with errors' do
          expect(execute).to be_error.and have_attributes(message: /Not valid to generate a trial/)
        end
      end

      context 'when namespace does not exist' do
        let(:trial_user_information) { { namespace_id: non_existing_record_id } }

        it 'returns success: false with errors' do
          expect(execute).to be_error.and have_attributes(message: /Not valid to generate a trial/)
        end
      end

      context 'when namespace is already on a trial', :saas do
        let_it_be(:namespace) { create(:group_with_plan, plan: :ultimate_trial_plan, trial_ends_on: 1.year.from_now) }
        let_it_be(:user) { create(:user).tap { |user| namespace.add_owner(user) } }

        it 'returns success: false with errors' do
          expect(execute).to be_error.and have_attributes(message: /Not valid to generate a trial/)
        end
      end
    end
  end

  describe '#valid_to_generate_trial?' do
    subject(:valid_to_generate_trial) { described_class.new(**apply_trial_params).valid_to_generate_trial? }

    context 'when it is valid to generate a trial' do
      it { is_expected.to be true }
    end

    context 'when namespace_id is not in the trial_user_information' do
      let(:trial_user_information) { {} }

      it { is_expected.to be false }
    end

    context 'when namespace does not exist' do
      let(:trial_user_information) { { namespace_id: non_existing_record_id } }

      it { is_expected.to be false }
    end

    context 'when namespace is already on a trial', :saas do
      let_it_be(:namespace) { create(:group_with_plan, plan: :ultimate_trial_plan, trial_ends_on: 1.year.from_now) }
      let_it_be(:user) { create(:user).tap { |user| namespace.add_owner(user) } }

      it { is_expected.to be false }
    end
  end
end
