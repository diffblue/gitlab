# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::PersonalAccessTokensHelper do
  let(:group) do
    build(:group, max_personal_access_token_lifetime: group_level_max_personal_access_token_lifetime)
  end

  let(:group_level_max_personal_access_token_lifetime) { nil }
  let(:instance_level_max_personal_access_token_lifetime) { nil }
  let(:user) { build(:user) }
  let(:managed_user) { build(:user, managing_group: group) }

  before do
    allow(helper).to receive(:current_user) { user }
    stub_application_setting(max_personal_access_token_lifetime: instance_level_max_personal_access_token_lifetime)
  end

  describe '#personal_access_token_expiration_policy_enabled?' do
    subject { helper.personal_access_token_expiration_policy_enabled? }

    context 'with `personal_access_token_expiration_policy` licensed' do
      before do
        stub_licensed_features(personal_access_token_expiration_policy: true)
      end

      shared_examples_for 'instance level PAT expiry setting' do
        context 'the instance has an expiry setting' do
          let(:instance_level_max_personal_access_token_lifetime) { 20 }

          it { is_expected.to be_truthy }
        end

        context 'the instance does not have an expiry setting' do
          it { is_expected.to be_falsey }
        end
      end

      context 'when the current user belongs to a managed group' do
        let(:user) { managed_user }

        context 'when the managed group has a PAT expiry policy' do
          let(:group_level_max_personal_access_token_lifetime) { 10 }

          it { is_expected.to be_truthy }
        end

        context 'when the managed group does not have a PAT expiry setting' do
          it_behaves_like 'instance level PAT expiry setting'
        end
      end

      context 'when the current user does not belong to a managed group' do
        it_behaves_like 'instance level PAT expiry setting'
      end
    end

    context 'with `personal_access_token_expiration_policy` not licensed' do
      before do
        stub_licensed_features(personal_access_token_expiration_policy: false)
      end

      shared_examples_for 'instance level PAT expiry setting' do
        context 'the instance has an expiry setting' do
          let(:instance_level_max_personal_access_token_lifetime) { 20 }

          it { is_expected.to be_falsey }
        end

        context 'the instance does not have an expiry setting' do
          it { is_expected.to be_falsey }
        end
      end

      context 'when the current user belongs to a managed group' do
        let(:user) { managed_user }

        context 'when the managed group has a PAT expiry policy' do
          let(:group_level_max_personal_access_token_lifetime) { 10 }

          it { is_expected.to be_falsey }
        end

        context 'when the managed group does not have a PAT expiry setting' do
          it_behaves_like 'instance level PAT expiry setting'
        end
      end

      context 'when the current user does not belong to a managed group' do
        it_behaves_like 'instance level PAT expiry setting'
      end
    end
  end

  describe '#personal_access_token_max_expiry_date' do
    subject { helper.personal_access_token_max_expiry_date }

    shared_examples_for 'instance level PAT expiry setting' do
      context 'the instance has an expiry setting' do
        let(:instance_level_max_personal_access_token_lifetime) { 20 }

        it { is_expected.to be_like_time(20.days.from_now) }
      end

      context 'the instance does not have an expiry setting' do
        it { is_expected.to be_nil }
      end
    end

    context 'when the current user belongs to a managed group' do
      let(:user) { managed_user }

      context 'when the managed group has a PAT expiry policy' do
        let(:group_level_max_personal_access_token_lifetime) { 10 }

        it { is_expected.to be_like_time(10.days.from_now) }
      end

      context 'when the managed group does not have a PAT expiry setting' do
        it_behaves_like 'instance level PAT expiry setting'
      end
    end

    context 'when the current user does not belong to a managed group' do
      it_behaves_like 'instance level PAT expiry setting'
    end
  end

  shared_examples 'feature availability' do
    context 'when feature is licensed' do
      before do
        stub_licensed_features(feature => true)
      end

      it { is_expected.to be_truthy }
    end

    context 'with `personal_access_token_expiration_policy` not licensed' do
      before do
        stub_licensed_features(feature => false)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#personal_access_token_expiration_policy_licensed?' do
    subject { helper.personal_access_token_expiration_policy_licensed? }

    let(:feature) { :personal_access_token_expiration_policy }

    it_behaves_like 'feature availability'
  end

  describe '#token_expiry_banner_message' do
    subject { helper.token_expiry_banner_message(user) }

    let_it_be(:user) { create(:user) }

    context 'when user has an expiring token requiring rotation' do
      let_it_be(:expiring_pat) { create(:personal_access_token, expires_at: 3.days.from_now, user: user, created_at: 1.month.ago) }

      it { is_expected.to eq('At least one of your Personal Access Tokens will expire soon. %{generate_new}') }
    end

    context 'when user has an expired token requiring rotation' do
      let_it_be(:expiring_pat) { create(:personal_access_token, :expired, user: user, created_at: 1.month.ago) }

      it { is_expected.to eq('At least one of your Personal Access Tokens is expired. %{generate_new}') }
    end
  end
end
