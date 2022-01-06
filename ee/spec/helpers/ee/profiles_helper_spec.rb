# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProfilesHelper do
  before do
    allow(Key).to receive(:enforce_ssh_key_expiration_feature_available?).and_return(true)
  end

  describe "#ssh_key_expiration_tooltip" do
    using RSpec::Parameterized::TableSyntax

    error_message = 'Key type is forbidden. Must be DSA, ECDSA, or ED25519'

    where(:error, :expired, :enforced, :result) do
      false | false | false | nil
      true  | false | false | error_message
      true  | false | true  | error_message
      true  | true  | false | error_message
      true  | true  | true  | 'Invalid key.'
      false | true  | true  | 'Expired key is not valid.'
      false | true  | false | 'Key usable beyond expiration date.'
    end

    with_them do
      let_it_be(:key) { build(:personal_key) }

      it do
        allow(Key).to receive(:expiration_enforced?).and_return(enforced)
        key.expires_at = expired ? 2.days.ago : 2.days.from_now
        key.errors.add(:base, error_message) if error

        expect(helper.ssh_key_expiration_tooltip(key)).to eq(result)
      end
    end

    context 'when enforced and expired' do
      let_it_be(:key) { build(:personal_key) }

      it 'does not return the expiration validation error message', :aggregate_failures do
        allow(Key).to receive(:expiration_enforced?).and_return(true)
        key.expires_at = 2.days.ago

        expect(key.invalid?).to eq(true)
        expect(helper.ssh_key_expiration_tooltip(key)).to eq('Expired key is not valid.')
      end
    end
  end

  describe "#ssh_key_expires_field_description" do
    using RSpec::Parameterized::TableSyntax

    where(:expiration_enforced, :result) do
      true  | "Key becomes invalid on this date."
      false | "Key can still be used after expiration."
    end

    with_them do
      it do
        allow(Key).to receive(:expiration_enforced?).and_return(expiration_enforced)

        expect(helper.ssh_key_expires_field_description).to eq(result)
      end
    end
  end

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
end
