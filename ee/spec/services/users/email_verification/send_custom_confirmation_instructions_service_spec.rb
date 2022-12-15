# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::EmailVerification::SendCustomConfirmationInstructionsService,
feature_category: :authentication_and_authorization do
  using RSpec::Parameterized::TableSyntax

  let(:service) { described_class.new(user) }
  let_it_be(:user) { build_stubbed(:user) }

  describe '#execute' do
    it 'calls `set_token` and `send_instructions`' do
      expect(service).to receive(:set_token)
      expect(service).to receive(:send_instructions)

      service.execute
    end
  end

  describe '#set_token' do
    subject { service.set_token(save: false) }

    context 'when not enabled' do
      before do
        allow(service).to receive(:enabled?).and_return(false)
      end

      it 'does not do anything' do
        expect { subject }.not_to change(user, :confirmation_token)
      end
    end

    context 'when enabled' do
      before do
        allow(service).to receive(:enabled?).and_return(true)

        allow_next_instance_of(::Users::EmailVerification::GenerateTokenService, attr: :confirmation_token) do |service|
          allow(service).to receive(:execute).and_return(%w[xxx token_digest])
        end
      end

      it 'skips Devise confirmation notification' do
        expect(user).to receive(:skip_confirmation_notification!)

        subject
      end

      it 'sets the confirmation_token and confirmation_sent_at attributes' do
        freeze_time do
          subject

          expect(user).to have_attributes(confirmation_token: 'token_digest', confirmation_sent_at: Time.current)
        end
      end

      it 'does not try to save the user' do
        expect(user).not_to receive(:save)

        subject
      end

      context 'when passing `save: true` as (default) argument' do
        it 'tries to save the user' do
          expect(user).to receive(:save)

          service.set_token
        end
      end
    end
  end

  describe '#send_instructions' do
    where(enabled?: [true, false],
          token_present?: [true, false],
          token_saved?: [true, false])

    with_them do
      before do
        allow(service).to receive(:enabled?).and_return(enabled?)
        allow(service).to receive(:token).and_return('xxx') if token_present?
        user.confirmation_token = 'yyy' unless token_saved?
      end

      after do
        user.restore_confirmation_token!
      end

      it 'sends the instructions when expected' do
        if enabled? && token_present? && token_saved?
          expect(::Notify).to receive(:confirmation_instructions_email)
              .with(user.email, token: 'xxx').once.and_call_original

          service.send_instructions
        elsif enabled?
          expect { service.send_instructions }.to raise_error service.class::SendConfirmationInstructionsError
        else
          expect(::Notify).not_to receive(:confirmation_instructions_email)

          service.send_instructions
        end
      end
    end
  end

  describe '#enabled?' do
    where(:identity_verification, :soft_email_confirmation,
      :require_admin_approval_after_user_signup, :email_confirmation_setting, :enabled?) do
      true  | true  | true  | 'hard' | false
      true  | true  | true  | 'off'  | false
      true  | true  | false | 'hard' | false
      true  | true  | false | 'off'  | false
      true  | false | true  | 'hard' | false
      true  | false | true  | 'off'  | false
      true  | false | false | 'hard' | true
      true  | false | false | 'off'  | false
      false | true  | true  | 'hard' | false
      false | true  | true  | 'off'  | false
      false | true  | false | 'hard' | false
      false | true  | false | 'off'  | false
      false | false | true  | 'hard' | false
      false | false | true  | 'off'  | false
      false | false | false | 'hard' | false
      false | false | false | 'off'  | false
    end

    with_them do
      before do
        stub_feature_flags(identity_verification: identity_verification)
        stub_feature_flags(soft_email_confirmation: soft_email_confirmation)
        stub_application_setting(require_admin_approval_after_user_signup: require_admin_approval_after_user_signup)
        stub_application_setting_enum('email_confirmation_setting', email_confirmation_setting)
      end

      it 'returns the expected result' do
        expect(!!service.enabled?).to eq(enabled?)
      end
    end
  end
end
