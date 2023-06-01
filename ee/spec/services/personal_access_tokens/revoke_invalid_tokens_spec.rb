# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokens::RevokeInvalidTokens, feature_category: :system_access do
  subject(:service) { described_class.new(user, expiration_date) }

  describe '#execute' do
    let(:expiration_date) { 10.days.from_now }

    let_it_be(:user) { create(:user) }
    let_it_be(:pat) { create(:personal_access_token, expires_at: 5.days.from_now, user: user) }
    let_it_be(:invalid_pat) { create(:personal_access_token, expires_at: 20.days.from_now, user: user) }

    before do
      stub_licensed_features(personal_access_token_expiration_policy: true)
    end

    shared_examples 'user does not receive revoke notification email' do
      it 'does not send any notification to user' do
        expect(Notify).not_to receive(:policy_revoked_personal_access_tokens_email).and_call_original

        service.execute
      end
    end

    context 'with a valid user and expiration date' do
      context 'with user tokens that will be revoked' do
        shared_examples 'revokes token' do
          it 'calls mailer to send an email notifying the user' do
            expect(Notify).to receive(:policy_revoked_personal_access_tokens_email).and_call_original

            service.execute
          end

          it "revokes invalid user's tokens" do
            service.execute

            expect(pat.reload).not_to be_revoked
            expect(invalid_pat.reload).to be_revoked
          end
        end

        shared_examples 'does not revoke token' do
          it_behaves_like 'user does not receive revoke notification email'

          it "does not revoke user's invalid tokens" do
            service.execute

            [pat, invalid_pat].each do |token_object|
              expect(token_object.reload).not_to be_revoked
            end
          end
        end

        it_behaves_like 'revokes token'

        context 'user optout for notifications' do
          before do
            allow(user).to receive(:can?).and_return(false)
          end

          it_behaves_like 'user does not receive revoke notification email'
        end
      end
    end

    context 'with no user' do
      let(:user) { nil }

      it_behaves_like 'user does not receive revoke notification email'

      it "doesn't revoke user's tokens" do
        expect { service.execute }.not_to change { pat.reload.revoked }
      end
    end

    context 'with no expiration date' do
      let(:expiration_date) { nil }

      it_behaves_like 'user does not receive revoke notification email'

      it "doesn't revoke user's tokens" do
        expect { service.execute }.not_to change { pat.reload.revoked }
      end
    end

    context 'when the licensed feature for personal access token policy is disabled' do
      before do
        stub_licensed_features(personal_access_token_expiration_policy: false)
      end

      it_behaves_like 'user does not receive revoke notification email'

      it "doesn't revoke user's tokens" do
        expect { service.execute }.not_to change { pat.reload.revoked }
      end
    end
  end
end
