# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('shared/credentials_inventory/personal_access_tokens/_personal_access_token.html.haml') do
  let_it_be(:user) { create(:user) }
  let_it_be(:expiry_date) { 20.days.since }
  let_it_be(:personal_access_token) { build_stubbed(:personal_access_token, user: user, expires_at: expiry_date) }

  before do
    freeze_time

    allow(view).to receive(:user_detail_path).and_return('abcd')
    allow(view).to receive(:personal_access_token_revoke_path).and_return('revoke')

    render 'shared/credentials_inventory/personal_access_tokens/personal_access_token', personal_access_token: personal_access_token
  end

  after do
    unfreeze_time
  end

  it 'shows the users name' do
    expect(rendered).to have_text(user.name)
  end

  it 'shows the created on date' do
    expect(rendered).to have_text(personal_access_token.created_at.to_date.to_s)
  end

  it 'shows the expiry date' do
    expect(rendered).to have_text(personal_access_token.expires_at.to_date.to_s)
  end

  context 'revoked date' do
    let_it_be(:updated_at_date) { 10.days.ago }

    before do
      render 'shared/credentials_inventory/personal_access_tokens/personal_access_token', personal_access_token: personal_access_token
    end

    context 'when revoked is set' do
      let_it_be(:personal_access_token) { build_stubbed(:personal_access_token, user: user, updated_at: updated_at_date, revoked: true) }

      it 'shows the revoked on date' do
        expect(rendered).to have_text(updated_at_date.to_date.to_s)
      end

      it 'does not show the revoke button' do
        expect(rendered).not_to have_css('a.btn', text: 'Revoke')
      end
    end

    context 'when revoked is not set' do
      let_it_be(:personal_access_token) { build_stubbed(:personal_access_token, user: user, updated_at: updated_at_date) }

      it 'does not show the revoked on date' do
        expect(rendered).not_to have_text(updated_at_date.to_date.to_s)
      end

      it 'shows the revoke button' do
        expect(rendered).to have_css('a.btn', text: 'Revoke')
      end
    end
  end

  context 'scopes' do
    context 'when set' do
      let_it_be(:scopes) { %w(api read_user read_api) }
      let_it_be(:personal_access_token) { build_stubbed(:personal_access_token, user: user, scopes: scopes) }

      it 'shows the scopes' do
        expect(rendered).to have_text(personal_access_token.scopes.join(', '))
      end
    end

    context 'when not set' do
      let_it_be(:personal_access_token) { build_stubbed(:personal_access_token, user: user) }

      before do
        # Turns out on creation of a PersonalAccessToken we set some default scopes and you can't pass `nil`
        # This is forcing the scope to be `nil` even though it looks impossible to do, we have the logic in the view
        personal_access_token.scopes = nil

        render 'shared/credentials_inventory/personal_access_tokens/personal_access_token', personal_access_token: personal_access_token
      end

      it 'shows "No Scopes"' do
        expect(rendered).to have_text('Scope No Scopes')
      end
    end
  end
end
