# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PhoneVerification::Users::SendVerificationCodeService, feature_category: :system_access do
  let_it_be_with_reload(:user) { create(:user) }
  let(:params) { { country: 'US', international_dial_code: 1, phone_number: '555' } }

  subject(:service) { described_class.new(user, params) }

  describe '#execute' do
    before do
      allow_next_instance_of(PhoneVerification::TelesignClient::RiskScoreService) do |instance|
        allow(instance).to receive(:execute).and_return(risk_service_response)
      end

      allow_next_instance_of(PhoneVerification::TelesignClient::SendVerificationCodeService) do |instance|
        allow(instance).to receive(:execute).and_return(send_verification_code_response)
      end

      allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
        .with(:phone_verification_send_code, scope: user).and_return(false)
    end

    context 'when params are invalid' do
      let(:params) { { country: 'US', international_dial_code: 1 } }

      it 'returns an error', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('Phone number can\'t be blank')
        expect(response.reason).to eq(:bad_params)
      end
    end

    context 'when user has reached max verification attempts' do
      let(:record) { create(:phone_number_validation, user: user) }

      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
        .with(:phone_verification_send_code, scope: user).and_return(true)
      end

      it 'returns an error', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq(
          'You\'ve reached the maximum number of tries. ' \
          'Wait about 1 hour and try again.'
        )
        expect(response.reason).to eq(:rate_limited)
      end
    end

    context 'when phone number is linked to an already banned user' do
      let(:banned_user) { create(:user, :banned) }
      let(:record) { create(:phone_number_validation, user: banned_user) }

      let(:params) do
        {
          country: 'AU',
          international_dial_code: record.international_dial_code,
          phone_number: record.phone_number
        }
      end

      it 'returns an error', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq(
          'There was a problem with the phone number you entered. '\
          'Enter a different phone number and try again.'
        )
        expect(response.reason).to eq(:related_to_banned_user)
      end
    end

    context 'when phone number is high risk' do
      let_it_be(:risk_service_response) do
        ServiceResponse.error(message: 'Downstream error message', reason: :invalid_phone_number)
      end

      it 'returns an error', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('Downstream error message')
        expect(response.reason).to eq(:invalid_phone_number)
      end
    end

    context 'when there is a client error in sending the verification code' do
      let_it_be(:risk_service_response) { ServiceResponse.success }

      let_it_be(:send_verification_code_response) do
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

    context 'when there is a TeleSign error in getting the risk score' do
      let_it_be(:risk_service_response) do
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
        record = user.phone_number_validation

        expect(record.validated_at).to eq(Time.now.utc)
        expect(record.risk_score).to eq(0)
        expect(record.telesign_reference_xid).to eq('unknown_telesign_error')
      end
    end

    context 'when there is a TeleSign error in sending the verification code' do
      let_it_be(:risk_service_response) { ServiceResponse.success }

      let_it_be(:send_verification_code_response) do
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
        record = user.phone_number_validation

        expect(record.validated_at).to eq(Time.now.utc)
        expect(record.risk_score).to eq(0)
        expect(record.telesign_reference_xid).to eq('unknown_telesign_error')
      end
    end

    context 'when there is a server error in sending the verification code' do
      let_it_be(:risk_service_response) { ServiceResponse.success }

      let_it_be(:send_verification_code_response) do
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
        allow_next_instance_of(PhoneVerification::TelesignClient::RiskScoreService) do |instance|
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

    context 'when verification code is sent successfully' do
      let_it_be(:risk_score) { 10 }
      let_it_be(:telesign_reference_xid) { '123' }

      let_it_be(:risk_service_response) do
        ServiceResponse.success(payload: { risk_score: risk_score })
      end

      let_it_be(:send_verification_code_response) do
        ServiceResponse.success(payload: { telesign_reference_xid: telesign_reference_xid })
      end

      it 'returns a success response', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_success
      end

      it 'saves the risk score, telesign_reference_xid and increases verification attempts', :aggregate_failures do
        service.execute
        record = user.phone_number_validation

        expect(record.risk_score).to eq(risk_score)
        expect(record.telesign_reference_xid).to eq(telesign_reference_xid)
      end
    end
  end
end
