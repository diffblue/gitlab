# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Telesign::TransactionCallbackPayload, feature_category: :instance_resiliency do
  let(:json) do
    # https://developer.telesign.com/enterprise/docs/transaction-callback-service#example-notification
    {
      status: {
        updated_on: '2016-07-08T20:52:46.417428Z',
        code: 200,
        description: 'Delivered to handset'
      },
      submit_timestamp: '2016-07-08T20:52:41.203000Z',
      errors: [
        { code: 501, description: 'Not authorized' },
        { code: 502, description: 'Campaign error' }
      ],
      verify: {
        code_state: 'VALID',
        code_entered: nil
      },
      sub_resource: 'sms',
      reference_id: '2557312299CC1304904080F4BE17BFB4'
    }.deep_stringify_keys
  end

  let(:response) { described_class.new(json) }

  describe '#reference_id' do
    subject { response.reference_id }

    it { is_expected.to eq '2557312299CC1304904080F4BE17BFB4' }

    context 'when there is no reference_id key' do
      let(:json) { {} }

      it { is_expected.to be_nil }
    end
  end

  describe '#status' do
    subject { response.status }

    it { is_expected.to eq '200 - Delivered to handset' }

    context 'when there are no status.code and status.description keys' do
      let(:json) { {} }

      it { is_expected.to eq '' }
    end
  end

  describe '#status_updated_on' do
    subject { response.status_updated_on }

    it { is_expected.to eq '2016-07-08T20:52:46.417428Z' }

    context 'when there is no status.updated_on key' do
      let(:json) { {} }

      it { is_expected.to be_nil }
    end
  end

  describe '#errors' do
    subject { response.errors }

    it { is_expected.to eq '501 - Not authorized, 502 - Campaign error' }

    context 'when errors is not an array' do
      let(:json) { {} }

      it { is_expected.to eq '' }
    end

    context 'when error object does not have code and description fields' do
      let(:json) { { errors: [{}] }.deep_stringify_keys }

      it { is_expected.to eq '' }
    end
  end
end
