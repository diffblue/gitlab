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
      context 'PATs of users that do not belong to a managed group' do
        context "when a token doesn't have an expiration time" do
          let(:expire_at) { nil }

          it 'enforces the policy on tokens' do
            expect { subject.perform }.to change { pat.reload.revoked }.from(false).to(true)
          end
        end

        context 'when a token expires after the limit' do
          let(:expire_at) { (instance_limit + 1).days.from_now.to_date }

          it 'enforces the policy on tokens' do
            expect { subject.perform }.to change { pat.reload.revoked }.from(false).to(true)
          end
        end
      end

      context 'PATs of users that belongs to a managed group' do
        let(:group) do
          create(:group_with_managed_accounts, max_personal_access_token_lifetime: group_limit)
        end

        let(:user) { create(:user, managing_group: group) }
        let!(:pat) { create(:personal_access_token, expires_at: expires_at, user: user) }

        context 'when the group has set a PAT expiry policy' do
          let(:group_limit) { 10 }

          context 'PAT invalid as per the instance PAT expiration policy' do
            let(:expires_at) { (instance_limit + 1).days.from_now.to_date }

            it 'does not revoke the PAT' do
              expect { subject.perform }.not_to change { pat.reload.revoked }
            end
          end

          context 'PAT invalid as per the group PAT expiration policy' do
            let(:expires_at) { (group_limit + 1).days.from_now.to_date }

            it 'does not revoke the PAT' do
              expect { subject.perform }.not_to change { pat.reload.revoked }
            end
          end
        end

        context 'when the group has not set a PAT expiry policy' do
          let(:group_limit) { nil }

          context 'PAT invalid as per the instance PAT expiration policy' do
            let(:expires_at) { (instance_limit + 1).days.from_now.to_date }

            it 'revokes the PAT' do
              expect { subject.perform }.to change { pat.reload.revoked }.from(false).to(true)
            end
          end

          context 'PAT valid as per the instance PAT expiration policy' do
            let(:expires_at) { (instance_limit - 1).days.from_now.to_date }

            it 'does not revoke the PAT' do
              expect { subject.perform }.not_to change { pat.reload.revoked }
            end
          end
        end
      end
    end
  end
end
