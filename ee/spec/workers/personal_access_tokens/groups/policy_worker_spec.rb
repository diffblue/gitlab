# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::Groups::PolicyWorker, type: :worker, feature_category: :system_access do
  let(:group) do
    create(:group_with_managed_accounts, max_personal_access_token_lifetime: limit)
  end

  let!(:pat) do
    create(:personal_access_token, expires_at: expires_at, user: create(:user, managing_group: group))
  end

  let(:limit) { 7 }
  let(:expires_after_max_token_lifetime) { (limit + 1).days.from_now.to_date }
  let(:expires_before_max_token_lifetime) { (limit - 1).days.from_now.to_date }

  describe '#perform' do
    subject do
      described_class.new.perform(group.id)
    end

    before do
      stub_licensed_features(personal_access_token_expiration_policy: true)
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [group.id] }
      let(:expires_at) { 1.month.from_now }

      context 'when the group has set a PAT expiry policy' do
        context 'valid PATs' do
          let(:expires_at) { expires_before_max_token_lifetime }

          it 'does not revoke valid PATs' do
            expect { subject }.not_to change { pat.reload.revoked }
          end
        end

        context 'invalid PATs' do
          let(:expires_at) { expires_after_max_token_lifetime }

          it 'revokes invalid PATs' do
            expect { subject }.to change { pat.reload.revoked }.from(false).to(true)
          end
        end
      end

      context 'when the group has not set a PAT expiry policy' do
        let(:group_limit) { nil }
        let(:expires_at) { 1.day.from_now.to_date }

        it 'does not revoke any tokens' do
          expect { subject }.not_to change { pat.reload.revoked }
        end
      end
    end
  end
end
