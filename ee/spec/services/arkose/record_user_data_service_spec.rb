# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arkose::RecordUserDataService, feature_category: :instance_resiliency do
  let(:user) { create(:user) }

  let(:arkose_verify_response) do
    Gitlab::Json.parse(File.read(Rails.root.join('ee/spec/fixtures/arkose/successfully_solved_ec_response.json')))
  end

  let(:response) { Arkose::VerifyResponse.new(arkose_verify_response) }
  let(:service) { described_class.new(response: response, user: user) }

  describe '#execute' do
    it 'adds new custom attributes to the user' do
      expect { service.execute }.to change { user.custom_attributes.count }.from(0).to(5)
    end

    it 'adds arkose data to custom attributes' do
      service.execute

      expect(user.custom_attributes.find_by(key: 'arkose_session').value).to eq('22612c147bb418c8.2570749403')
      expect(user.custom_attributes.find_by(key: 'arkose_device_id').value).to eq('gaFCZkxoGZYW6')
      expect(
        user.custom_attributes.find_by(key: UserCustomAttribute::ARKOSE_RISK_BAND).value
      ).to eq(Arkose::VerifyResponse::RISK_BAND_LOW)
      expect(user.custom_attributes.find_by(key: 'arkose_global_score').value).to eq('0')
      expect(user.custom_attributes.find_by(key: 'arkose_custom_score').value).to eq('0')
    end

    it 'returns a success response' do
      expect(service.execute).to be_success
    end

    context 'when response is from failed verification' do
      let(:arkose_verify_response) do
        Gitlab::Json.parse(File.read(Rails.root.join('ee/spec/fixtures/arkose/invalid_token.json')))
      end

      it 'does not add any custom attributes' do
        expect { service.execute }.not_to change { user.custom_attributes.count }
      end

      it 'returns an error response' do
        expect(service.execute).to be_error
      end
    end

    context 'when user is nil' do
      let(:user) { nil }

      it 'returns an error response' do
        expect(service.execute).to be_error
      end
    end
  end
end
