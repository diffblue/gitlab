# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Key do
  describe 'validations' do
    describe 'expiration' do
      using RSpec::Parameterized::TableSyntax

      where(:key, :expiration_enforced, :valid ) do
        build(:personal_key, expires_at: 2.days.ago) | true | false
        build(:personal_key, expires_at: 2.days.ago) | false | true
        build(:personal_key) | false | true
        build(:personal_key) | true | true
      end

      with_them do
        it 'checks if ssh key expiration is enforced' do
          expect(Key).to receive(:expiration_enforced?).and_return(expiration_enforced)

          expect(key.valid?).to eq(valid)
        end
      end
    end

    describe '#expires_at_before_max_expiry_date' do
      using RSpec::Parameterized::TableSyntax

      where(:key, :max_ssh_key_lifetime, :valid) do
        build(:personal_key, expires_at: 20.days.from_now) | 10 | false
        build(:personal_key, expires_at: 7.days.from_now) | 10 | true
        build(:personal_key, expires_at: 20.days.from_now) | nil | true
        build(:personal_key, expires_at: nil) | 20 | false
        build(:personal_key, expires_at: nil) | nil | true
      end

      with_them do
        before do
          stub_licensed_features(ssh_key_expiration_policy: true)
          stub_application_setting(max_ssh_key_lifetime: max_ssh_key_lifetime)
        end

        it 'checks if ssh key expiration is valid' do
          expect(key.valid?).to eq(valid)
        end
      end
    end
  end

  describe 'only_expired_and_enforced?' do
    using RSpec::Parameterized::TableSyntax

    where(:expired, :enforced, :valid, :result) do
      true | true | true | true
      true | false | true | false
      false | true | true | false
      true | true | false | true
      false | false | true | false
    end

    with_them do
      before do
        stub_licensed_features(enforce_ssh_key_expiration: true)
        stub_ee_application_setting(enforce_ssh_key_expiration: enforced)
      end

      it 'checks if ssh key expiration is enforced' do
        key = create(:personal_key)
        key.update_attribute(:expires_at, 3.days.ago) if expired
        key.update_attribute(:title, nil) unless valid

        expect(key.only_expired_and_enforced?).to be(result)
      end
    end
  end

  describe '.expiration_enforced?' do
    using RSpec::Parameterized::TableSyntax

    where(:licensed, :application_setting, :available) do
      true  | true  | true
      true  | false | false
      false | true  | false
      false | false | false
    end

    with_them do
      before do
        stub_licensed_features(enforce_ssh_key_expiration: licensed)
        stub_ee_application_setting(enforce_ssh_key_expiration: application_setting)
      end

      it 'checks if ssh key expiration is enforced' do
        expect(described_class.expiration_enforced?).to be(available)
      end
    end
  end

  describe '#audit_details' do
    it 'equals to the title' do
      key = build(:personal_key)
      expect(key.audit_details).to eq(key.title)
    end
  end
end
