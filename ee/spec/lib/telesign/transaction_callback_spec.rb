# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telesign::TransactionCallback, feature_category: :instance_resiliency do
  using RSpec::Parameterized::TableSyntax

  describe '#new' do
    let(:request) { instance_double(ActionDispatch::Request) }
    let(:request_params) { {} }

    subject { described_class.new(request, request_params) }

    it 'initializes the request and payload' do
      payload = instance_double(Telesign::TransactionCallbackPayload)
      expect(Telesign::TransactionCallbackPayload).to receive(:new).with(request_params).and_return(payload)

      expect(subject.request).to eq request
      expect(subject.payload).to eq payload
    end
  end

  describe '#valid?' do
    let(:request_params) { {} }

    subject { described_class.new(request, request_params).valid? }

    context 'when signature is not present in the headers' do
      let(:request) { instance_double(ActionDispatch::Request, headers: {}) }

      it { is_expected.to eq false }
    end

    context 'when signature is present in the headers' do
      let(:payload_string) { '{:ref_id=>"ref_id"}' }
      let(:request_params) { payload_string }
      let(:scheme) { described_class::AUTHORIZATION_SCHEME }
      let(:encoded_api_key) { Base64.encode64('secret_api_key') }
      let(:customer_id) { 'secret_customer_id' }
      # Base64.encode64(OpenSSL::HMAC.digest('SHA256', 'secret_api_key', '{:ref_id=>"ref_id"}'))
      let(:signature) { 'PJRdTwXX+/+nksJwXkEDLslxkX2rwUyyCHnlGslCsto=' }
      let(:authorization) { "#{scheme} #{customer_id}:#{signature}" }

      let(:request) do
        instance_double(
          ActionDispatch::Request,
          headers: { 'Authorization' => authorization },
          raw_post: request_params
        )
      end

      before do
        stub_ee_application_setting(
          telesign_customer_xid: customer_id,
          telesign_api_key: encoded_api_key
        )
      end

      it { is_expected.to eq true }

      context 'when Authorization header does not have the correct format' do
        where(:authorization, :payload) do
          ''                                                        | ref(:payload_string)
          'wrong auth'                                              | ref(:payload_string)
          "XYZ #{ref(:customer_id)}:#{ref(:signature)}"             | ref(:payload_string)
          "#{ref(:scheme)} wrong_customer_id:#{ref(:signature)}"    | ref(:payload_string)
          "#{ref(:scheme)} #{ref(:customer_id)}:wrong_signature"    | ref(:payload_string)
          "#{ref(:scheme)} #{ref(:customer_id)}:#{ref(:signature)}" | 'wrong payload'
        end

        with_them do
          let(:request_params) { payload }

          it { is_expected.to eq false }
        end
      end
    end
  end

  describe '#log' do
    let(:callback_valid) { true }
    let(:request_params) { {} }
    let(:reference_id) { 'ref_id' }
    let(:status) { 'sent' }
    let(:status_updated_on) { 'today' }
    let(:errors) { 'errors' }

    subject(:log) { described_class.new(instance_double(ActionDispatch::Request), request_params).log }

    before do
      allow_next_instance_of(described_class) do |callback|
        allow(callback).to receive(:valid?).and_return(callback_valid)
      end
    end

    it 'logs with the correct payload' do
      expect_next_instance_of(Telesign::TransactionCallbackPayload, request_params) do |response|
        expect(response).to receive(:reference_id).and_return(reference_id)
        expect(response).to receive(:status).and_return(status)
        expect(response).to receive(:status_updated_on).and_return(status_updated_on)
        expect(response).to receive(:errors).and_return(errors)
      end

      expect(Gitlab::AppJsonLogger).to receive(:info).with(
        hash_including(
          class: 'Telesign::TransactionCallback',
          message: 'IdentityVerification::Phone',
          event: 'Telesign transaction status update',
          telesign_reference_id: reference_id,
          telesign_status: status,
          telesign_status_updated_on: status_updated_on,
          telesign_errors: errors
        )
      )

      log
    end

    context 'when callback is not valid' do
      let(:callback_valid) { false }

      it 'does not log' do
        expect(Gitlab::AppJsonLogger).not_to receive(:info)

        log
      end
    end
  end
end
