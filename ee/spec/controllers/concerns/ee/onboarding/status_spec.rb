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
    where(:params, :trial?, :expected_result) do
      { user: { setup_for_company: true } } | false | true
      { user: { setup_for_company: false } } | false | false
      { user: {} } | false | false
      { user: { setup_for_company: true } } | true | true
      { user: { setup_for_company: false } } | true | true
      { user: {} } | true | true
    end

    with_them do
      let(:instance) { described_class.new(params, nil, nil) }

      subject { instance.redirect_to_company_form? }

      before do
        allow(instance).to receive(:trial?).and_return(trial?)
      end

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
