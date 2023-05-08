# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PhoneVerification::Users::VerifyCodeService, feature_category: :system_access do
  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:record) { create(:phone_number_validation, user: user, telesign_reference_xid: '123') }

  let(:params) { { verification_code: '999' } }

  subject(:service) { described_class.new(user, params) }

  describe '#execute' do
    before do
      allow_next_instance_of(PhoneVerification::TelesignClient::VerifyCodeService) do |instance|
        allow(instance).to receive(:execute).and_return(verify_response)
      end

      allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
        .with(:phone_verification_verify_code, scope: user).and_return(false)
    end

    context 'when params are invalid' do
      let(:params) { { verification_code: '' } }

      it 'returns an error', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('Verification code can\'t be blank.')
        expect(response.reason).to eq(:bad_params)
      end
    end

    context 'when user has reached max verification attempts' do
      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
        .with(:phone_verification_verify_code, scope: user).and_return(true)
      end

      it 'returns an error', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq(
          'You\'ve reached the maximum number of tries. ' \
          'Wait 10 minutes and try again.'
        )
        expect(response.reason).to eq(:rate_limited)
      end
    end

    context 'when there is a client error in sending the verification code' do
      let_it_be(:verify_response) do
        ServiceResponse.error(message: 'Downstream error message', reason: :bad_request)
      end

      it 'returns an error', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('Downstream error message')
        expect(response.reason).to eq(:bad_request)
      end
    end

    context 'when there is a TeleSign error in sending the verification code' do
      let_it_be(:verify_response) do
        ServiceResponse.error(message: 'Downstream error message', reason: :unknown_telesign_error)
      end

      it 'returns an error', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('Downstream error message')
        expect(response.reason).to eq(:unknown_telesign_error)
      end

      it 'force verifies the user', :aggregate_failures, :freeze_time do
        service.execute

        expect(record.reload.validated_at).to eq(Time.now.utc)
        expect(record.reload.telesign_reference_xid).to eq('unknown_telesign_error')
      end
    end

    context 'when there is a server error in sending the verification code' do
      let_it_be(:verify_response) do
        ServiceResponse.error(message: 'Downstream error message', reason: :internal_server_error)
      end

      it 'returns an error', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('Downstream error message')
        expect(response.reason).to eq(:internal_server_error)
      end
    end

    context 'when there is an unknown exception' do
      let(:exception) { StandardError.new }

      before do
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
        allow_next_instance_of(PhoneVerification::TelesignClient::VerifyCodeService) do |instance|
          allow(instance).to receive(:execute).and_raise(exception)
        end
      end

      it 'returns an error ServiceResponse', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('Something went wrong. Please try again.')
        expect(response.reason).to be(:internal_server_error)
      end

      it 'tracks the exception' do
        service.execute

        expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(
          exception, user_id: user.id
        )
      end
    end

    context 'when verification code is verified successfully' do
      let_it_be(:verify_response) do
        ServiceResponse.success(payload: { telesign_reference_xid: '123' })
      end

      it 'saves the validated_at timestamp', :freeze_time do
        service.execute
        expect(record.reload.validated_at).to eq(Time.now.utc)
      end

      it 'returns a success response', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_success
      end
    end
  end
end
