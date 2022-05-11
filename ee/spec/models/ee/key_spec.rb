# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Key do
  describe 'validations' do
    describe 'expiration' do
      using RSpec::Parameterized::TableSyntax

      where(:key, :valid ) do
        build(:personal_key, expires_at: 2.days.ago) | false
        build(:personal_key, expires_at: 2.days.from_now) | true
        build(:personal_key) | true
      end

      with_them do
        it 'checks if ssh key expiration is enforced' do
          expect(key.valid?).to eq(valid)
        end
      end
    end

    describe '#validate_expires_at_before_max_expiry_date' do
      using RSpec::Parameterized::TableSyntax

      context 'for a range of key expiry combinations' do
        where(:key, :max_ssh_key_lifetime, :valid) do
          build(:personal_key, created_at: Time.current, expires_at: nil) | nil | true
          build(:personal_key, created_at: Time.current, expires_at: 20.days.from_now) | nil | true
          build(:personal_key, created_at: 1.day.ago, expires_at: 20.days.from_now) | 10 | false
          build(:personal_key, created_at: 6.days.ago, expires_at: 3.days.from_now) | 10 | true
          build(:personal_key, created_at: 10.days.ago, expires_at: 7.days.from_now) | 10 | false
          build(:personal_key, created_at: Time.current, expires_at: nil) | 20 | false
          build(:personal_key, expires_at: nil) | 30 | false
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

      context 'when keys and max expiry are set' do
        where(:key, :max_ssh_key_lifetime, :valid) do
          build(:personal_key, created_at: Time.current, expires_at: 20.days.from_now) | 10 | false
          build(:personal_key, created_at: Time.current, expires_at: 7.days.from_now) | 10 | true
        end

        with_them do
          before do
            stub_licensed_features(ssh_key_expiration_policy: true)
            stub_application_setting(max_ssh_key_lifetime: max_ssh_key_lifetime)
          end
          it 'checks validity properly in the future too' do
            # Travel to the day before the key is set to 'expire'.
            # max_ssh_key_lifetime should still be enforced correctly.
            travel_to(key.expires_at - 1) do
              expect(key.valid?).to eq(valid)
            end
          end
        end
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
