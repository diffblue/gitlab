# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::Instance::PolicyWorker, type: :worker, feature_category: :system_access do
  describe '#perform' do
    let(:instance_limit) { 7 }
    let!(:pat) { create(:personal_access_token, expires_at: expire_at) }

    before do
      stub_application_setting(max_personal_access_token_lifetime: instance_limit)
      stub_licensed_features(personal_access_token_expiration_policy: true)
    end

    context 'when a token is valid' do
      let(:expire_at) { (instance_limit - 1).days.from_now.to_date }

      it "doesn't revoked valid tokens" do
        expect { subject.perform }.not_to change { pat.reload.revoked }
      end
    end

    context 'when limit is nil' do
      let(:instance_limit) { nil }
      let(:expire_at) { 1.day.from_now }

      it "doesn't revoked valid tokens" do
        expect { subject.perform }.not_to change { pat.reload.revoked }
      end

      it "doesn't call the revoke invalid service" do
        expect(PersonalAccessTokens::RevokeInvalidTokens).not_to receive(:new)

        subject.perform
      end
    end

    context 'invalid tokens' do
      context 'when a token expires after the limit' do
        let(:expire_at) { (instance_limit + 1).days.from_now.to_date }

        it 'enforces the policy on tokens' do
          expect { subject.perform }.to change { pat.reload.revoked }.from(false).to(true)
        end
      end
    end
  end
end
