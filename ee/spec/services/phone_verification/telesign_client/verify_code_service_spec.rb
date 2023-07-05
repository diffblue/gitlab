# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PhoneVerification::TelesignClient::VerifyCodeService, feature_category: :system_access do
  let(:telesign_customer_xid) { 'foo' }
  let(:telesign_api_key) { 'bar' }

  let(:user) { build(:user) }
  let(:telesign_reference_xid) { '360F69274E0813049191FB5A94308801' }
  let(:verification_code) { '123456' }

  subject(:service) do
    described_class.new(
      telesign_reference_xid: telesign_reference_xid,
      verification_code: verification_code,
      user: user
    )
  end

  before do
    allow_next_instance_of(TelesignEnterprise::VerifyClient) do |instance|
      allow(instance).to receive(:status).and_return(telesign_response)
    end
  end

  describe '#execute' do
    context 'when verification code is verified successfully' do
      let(:telesign_response) do
        instance_double(
          Telesign::RestClient::Response,
          json: {
            'reference_id' => telesign_reference_xid,
            'verify' => { 'code_state' => 'VALID' },
            'status' => { 'description' => 'Transaction completed successfully' }
          },
          status_code: '200'
        )
      end

      it 'returns a success ServiceResponse', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_success
        expect(response.payload).to eq({ telesign_reference_xid: telesign_reference_xid })
      end

      it 'logs an info message' do
        expect(::Gitlab::AppJsonLogger)
          .to receive(:info)
          .with(
            class: described_class.name,
            message: 'IdentityVerification::Phone',
            event: 'Verified a phone verification code with Telesign',
            telesign_reference_id: telesign_reference_xid,
            telesign_response: telesign_response.json['status']['description'],
            telesign_status_code: telesign_response.status_code,
            username: user.username
          )
          .and_call_original

        service.execute
      end
    end

    context 'when code is invalid' do
      let(:telesign_response) do
        instance_double(
          Telesign::RestClient::Response,
          json: {
            'reference_id' => telesign_reference_xid,
            'verify' => { 'code_state' => 'INVALID' }
          },
          status_code: '200'
        )
      end

      it 'returns an error ServiceResponse', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('Enter a valid code.')
        expect(response.reason).to eq(:invalid_code)
      end
    end

    context 'when code has expired' do
      let(:telesign_response) do
        instance_double(
          Telesign::RestClient::Response,
          json: {
            'reference_id' => telesign_reference_xid,
            'verify' => { 'code_state' => 'EXPIRED' }
          },
          status_code: '200'
        )
      end

      it 'returns an error ServiceResponse', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('The code has expired. Request a new code and try again.')
        expect(response.reason).to eq(:invalid_code)
      end
    end

    context 'when max attempts have been reached for a code' do
      let(:telesign_response) do
        instance_double(
          Telesign::RestClient::Response,
          json: {
            'reference_id' => telesign_reference_xid,
            'verify' => { 'code_state' => 'MAX_ATTEMPTS_EXCEEDED' }
          },
          status_code: '200'
        )
      end

      it 'returns an error ServiceResponse', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('You\'ve reached the maximum number of tries. Request a new code and try again.')
        expect(response.reason).to eq(:invalid_code)
      end
    end

    context 'when TeleSign returns an unsuccessful response' do
      let(:telesign_response) do
        instance_double(
          Telesign::RestClient::Response,
          json: {
            'errors' => [
              { 'code' => -40008, 'description' => 'Transaction not attempted' }
            ]
          },
          status_code: '500'
        )
      end

      it 'returns an error ServiceResponse', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('Something went wrong. Please try again.')
        expect(response.reason).to eq(:unknown_telesign_error)
      end

      it 'logs the error message' do
        expect(::Gitlab::AppJsonLogger)
          .to receive(:info)
          .with(
            hash_including(
              telesign_response: "error_message: Transaction not attempted, error_code: -40008"
            )
          )
          .and_call_original

        service.execute
      end
    end

    context 'when there is a timeout error' do
      let(:exception) { Timeout::Error }

      before do
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
        allow_next_instance_of(TelesignEnterprise::VerifyClient) do |instance|
          allow(instance).to receive(:status).and_raise(exception)
        end
      end

      it 'returns an error ServiceResponse', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('Something went wrong. Please try again.')
        expect(response.reason).to be(:unknown_telesign_error)
      end
    end

    context 'when there is an unknown exception' do
      let(:exception) { StandardError.new }

      before do
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
        allow_next_instance_of(TelesignEnterprise::VerifyClient) do |instance|
          allow(instance).to receive(:status).and_raise(exception)
        end
      end

      it 'returns an error ServiceResponse', :aggregate_failures do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq('Something went wrong. Please try again.')
        expect(response.reason).to eq(:internal_server_error)
      end

      it 'tracks the exception' do
        service.execute

        expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(
          exception, user_id: user.id
        )
      end
    end
  end
end
