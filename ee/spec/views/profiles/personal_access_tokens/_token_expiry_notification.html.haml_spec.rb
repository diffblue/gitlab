# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/personal_access_tokens/_token_expiry_notification.html.haml' do
  let_it_be(:user) { build(:user) }
  let_it_be(:active_tokens) { build_list(:personal_access_token, 2) }
  let_it_be(:expired_tokens) { build_list(:personal_access_token, 2, expires_at: 5.days.ago) }
  let_it_be(:one_expired_token) { [build(:personal_access_token, expires_at: 5.days.ago)] }

  context 'when the notification should be shown' do
    before do
      stub_licensed_features(enforce_personal_access_token_expiration: true)
      allow(Gitlab::CurrentSettings).to receive(:enforce_pat_expiration?).and_return(false)
      allow(view).to receive(:show_profile_token_expiry_notification?).and_return(true)
    end

    context 'when there are expired tokens' do
      before do
        render 'profiles/personal_access_tokens/token_expiry_notification', active_tokens: expired_tokens
      end

      it 'contains the correct content', :aggregate_failures do
        expect(rendered).to have_selector '[data-feature-id="profile_personal_access_token_expiry"]'
        expect(rendered).to match /<use href=".+?icons-.+?#error">/
        expect(rendered).to have_content '2 tokens have expired'
        expect(rendered).to have_content 'Until revoked, expired personal access tokens pose a security risk.'
      end
    end

    context 'when there is one expired token' do
      before do
        render 'profiles/personal_access_tokens/token_expiry_notification', active_tokens: one_expired_token
      end

      it 'has the singular title' do
        expect(rendered).to have_content '1 token has expired'
      end
    end
  end
end
