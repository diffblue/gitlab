# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::EmailVerification::SendCustomConfirmationInstructionsService,
feature_category: :system_access do
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

        allow_next_instance_of(::Users::EmailVerification::GenerateTokenService) do |service|
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
    where(confirmed?: [true, false],
      identity_verification_enabled?: [true, false],
      token_present?: [true, false],
      token_saved?: [true, false])

    with_them do
      before do
        user.restore_confirmation_token!
        allow(user).to receive(:confirmed?).and_return(confirmed?)
        allow(user).to receive(:identity_verification_enabled?).and_return(identity_verification_enabled?)
        allow(service).to receive(:token).and_return('xxx') if token_present?
        user.confirmation_token = 'yyy' unless token_saved?
      end

      it 'sends the instructions when expected' do
        if !confirmed? && identity_verification_enabled? && token_present? && token_saved?
          expect(::Notify).to receive(:confirmation_instructions_email)
              .with(user.email, token: 'xxx').once.and_call_original

          service.send_instructions
        elsif !confirmed? && identity_verification_enabled?
          expect { service.send_instructions }.to raise_error service.class::SendConfirmationInstructionsError
        else
          expect(::Notify).not_to receive(:confirmation_instructions_email)

          service.send_instructions
        end
      end
    end
  end
end
