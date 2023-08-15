# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::Status, feature_category: :onboarding do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:member) { create(:group_member) }
  let_it_be(:user) { member.user }

  describe '#continue_full_onboarding?' do
    let(:instance) { described_class.new(nil, nil, nil) }

    subject { instance.continue_full_onboarding? }

    where(
      subscription?: [true, false],
      invite?: [true, false],
      oauth?: [true, false],
      enabled?: [true, false]
    )

    with_them do
      let(:expected_result) { !subscription? && !invite? && !oauth? && enabled? }

      before do
        allow(instance).to receive(:subscription?).and_return(subscription?)
        allow(instance).to receive(:invite?).and_return(invite?)
        allow(instance).to receive(:oauth?).and_return(oauth?)
        allow(instance).to receive(:enabled?).and_return(enabled?)
      end

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#redirect_to_company_form?' do
    where(:setup_for_company?, :trial?, :expected_result) do
      true  | false | true
      false | false | false
      false | true  | true
    end

    with_them do
      let(:instance) { described_class.new({}, nil, nil) }

      subject { instance.redirect_to_company_form? }

      before do
        allow(instance).to receive(:trial?).and_return(trial?)
        allow(instance).to receive(:setup_for_company?).and_return(setup_for_company?)
      end

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#setup_for_company?' do
    where(:params, :expected_result) do
      { user: { setup_for_company: true } }  | true
      { user: { setup_for_company: false } } | false
      { user: {} }                           | false
    end

    with_them do
      let(:instance) { described_class.new(params, nil, nil) }

      subject { instance.setup_for_company? }

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#invite?' do
    subject { described_class.new(nil, nil, user).invite? }

    context 'with members for the user' do
      it { is_expected.to eq(true) }
    end

    context 'without members for the user' do
      let(:user) { build_stubbed(:user) }

      it { is_expected.to eq(false) }
    end
  end

  describe '#joining_a_project?' do
    where(:params, :expected_result) do
      { joining_project: 'true' }  | true
      { joining_project: 'false' } | false
      {}                           | false
      { joining_project: '' }      | false
    end

    with_them do
      let(:instance) { described_class.new(params, nil, nil) }

      subject { instance.joining_a_project? }

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#trial_onboarding_flow?' do
    where(:params, :expected_result) do
      { trial_onboarding_flow: 'true' }  | true
      { trial_onboarding_flow: 'false' } | false
      {}                                 | false
      { trial_onboarding_flow: '' }      | false
    end

    with_them do
      let(:instance) { described_class.new(params, nil, nil) }

      subject { instance.trial_onboarding_flow? }

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#tracking_label' do
    let(:instance) { described_class.new({}, nil, nil) }
    let(:trial?) { false }
    let(:invite?) { false }

    subject(:tracking_label) { instance.tracking_label }

    before do
      allow(instance).to receive(:trial?).and_return(trial?)
      allow(instance).to receive(:invite?).and_return(invite?)
    end

    it { is_expected.to eq('free_registration') }

    context 'when it is a trial' do
      let(:trial?) { true }

      it { is_expected.to eq('trial_registration') }
    end

    context 'when it is an invite' do
      let(:invite?) { true }

      it { is_expected.to eq('invite_registration') }
    end
  end

  describe '#onboarding_tracking_label' do
    let(:instance) { described_class.new({}, nil, nil) }
    let(:trial_onboarding_flow?) { false }

    subject(:tracking_label) { instance.onboarding_tracking_label }

    before do
      allow(instance).to receive(:trial_onboarding_flow?).and_return(trial_onboarding_flow?)
    end

    it { is_expected.to eq('free_registration') }

    context 'when it is a trial_onboarding_flow' do
      let(:trial_onboarding_flow?) { true }

      it { is_expected.to eq('trial_registration') }
    end
  end

  describe '#group_creation_tracking_label' do
    where(:trial_onboarding_flow?, :trial?, :expected_result) do
      true  | true  | 'trial_registration'
      true  | false | 'trial_registration'
      false | true  | 'trial_registration'
      false | false | 'free_registration'
    end

    with_them do
      let(:instance) { described_class.new({}, nil, nil) }

      subject { instance.group_creation_tracking_label }

      before do
        allow(instance).to receive(:trial_onboarding_flow?).and_return(trial_onboarding_flow?)
        allow(instance).to receive(:trial?).and_return(trial?)
      end

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#trial?' do
    where(:params, :enabled?, :expected_result) do
      { trial: 'true' } | false | false
      { trial: 'false' } | true | false
      { trial: 'true' } | true | true
      { trial: 'false' } | false | false
      {} | true | false
      {} | false | false
      { trial: '' } | false | false
      { trial: '' } | true | false
    end

    with_them do
      let(:instance) { described_class.new(params, nil, nil) }

      subject { instance.trial? }

      before do
        allow(instance).to receive(:enabled?).and_return(enabled?)
      end

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#oauth?' do
    let(:return_to) { nil }
    let(:session) { { 'user_return_to' => return_to } }

    subject { described_class.new(nil, session, nil).oauth? }

    context 'when in oauth' do
      let(:return_to) { ::Gitlab::Routing.url_helpers.oauth_authorization_path }

      it { is_expected.to eq(true) }

      context 'when there are params on the oauth path' do
        let(:return_to) { ::Gitlab::Routing.url_helpers.oauth_authorization_path(some_param: '_param_') }

        it { is_expected.to eq(true) }
      end
    end

    context 'when not in oauth' do
      context 'when no user location is stored' do
        it { is_expected.to eq(false) }
      end

      context 'when user location does not indicate oauth' do
        let(:return_to) { '/not/oauth/path' }

        it { is_expected.to eq(false) }
      end

      context 'when user location does not have value in session' do
        let(:session) { {} }

        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#enabled?' do
    subject { described_class.new(nil, nil, nil).enabled? }

    context 'when on SaaS', :saas do
      it { is_expected.to eq(true) }
    end

    context 'when not on SaaS' do
      it { is_expected.to eq(false) }
    end
  end

  describe '#subscription?' do
    let(:return_to) { ::Gitlab::Routing.url_helpers.new_subscriptions_path }
    let(:session) { { 'user_return_to' => return_to } }

    subject { described_class.new(nil, session, nil).subscription? }

    context 'when on SaaS', :saas do
      context 'when in subscription flow' do
        it { is_expected.to eq(true) }
      end

      context 'when not in subscription flow' do
        context 'when no user location is stored' do
          let(:return_to) { nil }

          it { is_expected.to eq(false) }
        end

        context 'when user location does not indicate subscription' do
          let(:return_to) { '/not/subscription/path' }

          it { is_expected.to eq(false) }
        end

        context 'when user location does not have value in session' do
          let(:session) { {} }

          it { is_expected.to eq(false) }
        end
      end
    end

    context 'when not on SaaS' do
      it { is_expected.to eq(false) }
    end
  end

  describe '#iterable_product_interaction' do
    subject { described_class.new(nil, nil, user).iterable_product_interaction }

    context 'with members for the user' do
      it { is_expected.to eq('Invited User') }
    end

    context 'without members for the user' do
      let(:user) { build_stubbed(:user) }

      it { is_expected.to eq('Personal SaaS Registration') }
    end
  end

  describe '#eligible_for_iterable_trigger?' do
    let(:instance) { described_class.new(nil, nil, nil) }

    subject { instance.eligible_for_iterable_trigger? }

    where(
      trial?: [true, false],
      invite?: [true, false],
      redirect_to_company_form?: [true, false],
      continue_full_onboarding?: [true, false]
    )

    with_them do
      let(:expected_result) do
        (!trial? && invite?) || (!trial? && !redirect_to_company_form? && continue_full_onboarding?)
      end

      before do
        allow(instance).to receive(:trial?).and_return(trial?)
        allow(instance).to receive(:invite?).and_return(invite?)
        allow(instance).to receive(:redirect_to_company_form?).and_return(redirect_to_company_form?)
        allow(instance).to receive(:continue_full_onboarding?).and_return(continue_full_onboarding?)
      end

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#stored_user_location' do
    let(:return_to) { nil }
    let(:session) { { 'user_return_to' => return_to } }

    subject { described_class.new(nil, session, nil).stored_user_location }

    context 'when no user location is stored' do
      it { is_expected.to be_nil }
    end

    context 'when user location exists' do
      let(:return_to) { '/some/path' }

      it { is_expected.to eq(return_to) }
    end

    context 'when user location does not have value in session' do
      let(:session) { {} }

      it { is_expected.to be_nil }
    end
  end
end
