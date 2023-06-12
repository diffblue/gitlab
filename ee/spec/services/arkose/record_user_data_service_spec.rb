# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Arkose::RecordUserDataService, feature_category: :instance_resiliency do
  let(:user) { create(:user) }

  let(:arkose_verify_response) do
    Gitlab::Json.parse(File.read(Rails.root.join('ee/spec/fixtures/arkose/successfully_solved_ec_response.json')))
  end

  let(:response) { Arkose::VerifyResponse.new(arkose_verify_response) }
  let(:service) { described_class.new(response: response, user: user) }
  let(:user_scores) { Abuse::UserTrustScore.new(user) }

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

    it 'stores risk scores in abuse trust scores' do
      # Create and store initial scores
      create(:abuse_trust_score, user: user, score: 12.0, source: :arkose_global_score)
      create(:abuse_trust_score, user: user, score: 15.0, source: :arkose_custom_score)

      service.execute

      # Response mock json values from arkose_verify_response are stored after executing the service,
      # we should expect `arkose_global_score` and `arkose_custom_score` to point to these values
      expect(user_scores.arkose_global_score).to eq(0.0)
      expect(user_scores.arkose_custom_score).to eq(0.0)
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

      it 'does not store the arkose risk scores in abuse trust scores' do
        # Create and store initial scores
        create(:abuse_trust_score, user: user, score: 13.0, source: :arkose_global_score)
        create(:abuse_trust_score, user: user, score: 11.0, source: :arkose_custom_score)
        service.execute

        # Due to failed verification, there are no returned scores in arkose_verify_response,
        # we should expect `arkose_global_score` and `arkose_custom_score` not to be overwritten
        # and remain as the initial scores
        expect(user_scores.arkose_global_score).to eq(13.0)
        expect(user_scores.arkose_custom_score).to eq(11.0)
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
