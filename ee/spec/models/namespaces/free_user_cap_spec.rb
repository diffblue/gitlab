# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::FreeUserCap, feature_category: :experimentation_conversion do
  using RSpec::Parameterized::TableSyntax

  describe '.notification_or_enforcement_enabled?' do
    let(:namespace) { build(:namespace) }

    subject { described_class.notification_or_enforcement_enabled?(namespace) }

    where(:enforce_preview, :enforce_standard, :result) do
      true  | true  | true
      true  | false | true
      false | true  | true
      false | false | false
    end

    before do
      allow_next_instance_of(::Namespaces::FreeUserCap::Notification, namespace) do |instance|
        allow(instance).to receive(:enforce_cap?).and_return(enforce_preview)
      end

      allow_next_instance_of(::Namespaces::FreeUserCap::Enforcement, namespace) do |instance|
        allow(instance).to receive(:enforce_cap?).and_return(enforce_standard)
      end
    end

    with_them do
      it { is_expected.to be result }
    end
  end

  describe '.over_user_limit_mails_enabled?' do
    subject { described_class.over_user_limit_mails_enabled? }

    context 'when feature flag is enabled' do
      it { is_expected.to be_truthy }
    end

    context 'when feature flag is disabled' do
      it 'reflects the state of the feature flag' do
        stub_feature_flags free_user_cap_over_user_limit_mails: false

        expect(subject).to be_falsey
      end
    end
  end

  describe '.dashboard_limit' do
    subject { described_class.dashboard_limit }

    context 'when set to default' do
      it { is_expected.to eq 0 }
    end

    context 'when not set to default' do
      before do
        stub_ee_application_setting(dashboard_limit: 5)
      end

      it { is_expected.to eq 5 }
    end
  end

  describe '.owner_access?' do
    let_it_be(:user) { create(:user) }
    let_it_be(:namespace) { create(:group) }

    subject(:access) { described_class.owner_access?(user: user, namespace: namespace) }

    context 'when user is not provided' do
      let(:user) { nil }

      it 'returns false' do
        expect(access).to be(false)
      end
    end

    context 'when user does not have owner access' do
      it 'returns false' do
        namespace.add_developer(user)

        expect(access).to be(false)
      end
    end

    context 'when user has owner access' do
      it 'returns true' do
        namespace.add_owner(user)

        expect(access).to be(true)
      end
    end
  end

  describe '.non_owner_access?' do
    let_it_be(:user) { create(:user) }
    let_it_be(:namespace) { create(:group) }

    subject(:access) { described_class.non_owner_access?(user: user, namespace: namespace) }

    context 'when user is not provided' do
      let(:user) { nil }

      it 'returns false' do
        expect(access).to be(false)
      end
    end

    context 'when user does not have owner access' do
      it 'returns true' do
        namespace.add_developer(user)

        expect(access).to be(true)
      end
    end

    context 'when user has owner access' do
      it 'returns false' do
        namespace.add_owner(user)

        expect(access).to be(false)
      end
    end
  end
end
