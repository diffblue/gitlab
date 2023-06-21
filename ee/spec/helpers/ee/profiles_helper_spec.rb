# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProfilesHelper do
  describe '#ssh_key_expiration_policy_licensed?' do
    subject { helper.ssh_key_expiration_policy_licensed? }

    context 'when is not licensed' do
      before do
        stub_licensed_features(ssh_key_expiration_policy: false)
      end

      it { is_expected.to be_falsey }
    end

    context 'when is licensed' do
      before do
        stub_licensed_features(ssh_key_expiration_policy: true)
      end

      it { is_expected.to be_truthy }
    end
  end

  describe "#ssh_key_expires_field_description" do
    using RSpec::Parameterized::TableSyntax

    where(:policy_enabled, :result) do
      true | format(s_('Profiles|Key becomes invalid on this date. Maximum lifetime for SSH keys is ' \
                       '%{max_ssh_key_lifetime} days'), max_ssh_key_lifetime: 10)
      false | s_('Profiles|Optional but recommended. If set, key becomes invalid on the specified date.')
    end

    with_them do
      before do
        stub_licensed_features(ssh_key_expiration_policy: policy_enabled)
        stub_application_setting(max_ssh_key_lifetime: 10)
      end

      it do
        expect(helper.ssh_key_expires_field_description).to eq(result)
      end
    end
  end

  describe '#ssh_key_expiration_policy_enabled?' do
    subject { helper.ssh_key_expiration_policy_enabled? }

    context 'when is licensed and used' do
      before do
        stub_licensed_features(ssh_key_expiration_policy: true)
        stub_application_setting(max_ssh_key_lifetime: 10)
      end

      it { is_expected.to be_truthy }
    end

    context 'when is not licensed' do
      before do
        stub_licensed_features(ssh_key_expiration_policy: false)
      end

      it { is_expected.to be_falsey }
    end

    context 'when is licensed but not used' do
      before do
        stub_licensed_features(ssh_key_expiration_policy: true)
        stub_application_setting(max_ssh_key_lifetime: nil)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#prevent_delete_account?' do
    subject { helper.prevent_delete_account? }

    using RSpec::Parameterized::TableSyntax

    where(:license_feature, :allow_account_deletion, :result) do
      true  | true  | false
      true  | false | true
      false | true  | false
      false | false | false
    end

    with_them do
      before do
        stub_licensed_features(disable_deleting_account_for_users: license_feature)
        stub_application_setting(allow_account_deletion: allow_account_deletion)
      end

      it { is_expected.to eq(result) }
    end
  end
end
