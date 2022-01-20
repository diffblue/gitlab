# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::RegistrationsHelper do
  include Devise::Test::ControllerHelpers

  describe '#signup_username_data_attributes' do
    it 'has expected attributes' do
      expect(helper.signup_username_data_attributes.keys).to include(:api_path)
    end
  end

  describe '#shuffled_registration_objective_options' do
    subject(:shuffled_options) { helper.shuffled_registration_objective_options }

    it 'has values that match all UserDetail registration objective keys' do
      shuffled_option_values = shuffled_options.map { |item| item.last }

      expect(shuffled_option_values).to contain_exactly(*UserDetail.registration_objectives.keys)
    end

    it '"other" is always the last option' do
      expect(shuffled_options.last).to eq(['A different reason', 'other'])
    end

    context 'when the bypass_registration experiment is candidate', :experiment do
      before do
        stub_experiments({ bypass_registration: :candidate })
      end

      it "excludes the joining_team option" do
        shuffled_option_values = shuffled_options.map { |item| item.last }
        expect(shuffled_option_values).to contain_exactly(*UserDetail.registration_objectives.keys.reject {|k| k == "joining_team"})
      end
    end
  end

  describe '#registration_verification_enabled?' do
    let_it_be(:current_user) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(current_user)
    end

    subject(:action) { helper.registration_verification_enabled? }

    context 'when experiment is candidate' do
      before do
        stub_experiments(registration_verification: :candidate)
      end

      it { is_expected.to eq(true) }
    end

    context 'when experiment is control' do
      before do
        stub_experiments(registration_verification: :control)
      end

      it { is_expected.to be_falsey }
    end

    it_behaves_like 'tracks assignment and records the subject', :registration_verification, :user do
      subject { current_user }
    end
  end

  describe '#registration_verification_data' do
    before do
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(params))
      allow(helper).to receive(:current_user).and_return(build(:user, setup_for_company: setup_for_company))
    end

    let(:setup_for_company) { false }

    context 'with `learn_gitlab_project_id` parameter present' do
      let(:params) { { learn_gitlab_project_id: 1 } }

      it 'return expected data' do
        expect(helper.registration_verification_data)
          .to eq(next_step_url: helper.trial_getting_started_users_sign_up_welcome_path(params))
      end
    end

    context 'with `project_id` parameter present' do
      let(:params) { { project_id: 1 } }

      it 'return expected data' do
        expect(helper.registration_verification_data)
          .to eq(next_step_url: helper.continuous_onboarding_getting_started_users_sign_up_welcome_path(params))
      end
    end

    context 'with `combined` parameter present' do
      let(:params) { { combined: true } }

      context 'when user is setting up for a company' do
        let(:setup_for_company) { true }

        it 'return expected data' do
          expect(helper.registration_verification_data)
            .to eq(next_step_url: helper.new_trial_path)
        end
      end

      context 'when user is not setting up for a company' do
        it 'return expected data' do
          expect(helper.registration_verification_data)
            .to eq(next_step_url: helper.root_path)
        end
      end
    end

    context 'with no relevant parameters present' do
      let(:params) { { xxx: 1 } }

      it 'return expected data' do
        expect(helper.registration_verification_data).to eq(next_step_url: helper.root_path)
      end
    end
  end

  describe '#credit_card_verification_data' do
    before do
      allow(helper).to receive(:current_user).and_return(build(:user))
    end

    it 'returns the expected data' do
      expect(helper.credit_card_verification_data).to eq(
        {
          completed: 'false',
          iframe_url: ::Gitlab::SubscriptionPortal::REGISTRATION_VALIDATION_FORM_URL,
          allowed_origin: ::Gitlab::SubscriptionPortal::SUBSCRIPTIONS_URL
        }
      )
    end
  end
end
