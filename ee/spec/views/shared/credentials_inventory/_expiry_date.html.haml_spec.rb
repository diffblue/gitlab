# frozen_string_literal: true

require 'spec_helper'

RSpec.describe('shared/credentials_inventory/_expiry_date.html.haml') do
  let_it_be(:user) { create(:user) }

  before do
    render 'shared/credentials_inventory/expiry_date', credential: credential
  end

  context 'when a non-expirable credential is used' do
    let_it_be(:credential) { create(:deploy_key, user: user) }

    it 'shows "Never" if expires? method does not exist' do
      expect(rendered).to have_text('Never')
    end
  end

  context 'when an expirable credential is used' do
    context 'and is not expired' do
      let_it_be(:expiry_date) { 20.days.since.to_date.to_s }
      let_it_be(:credential) { create(:personal_key, user: user, expires_at: expiry_date) }

      it 'shows the correct date' do
        expect(rendered).to have_text(expiry_date)
      end

      it 'does not have an expiry icon' do
        expect(rendered).not_to have_selector('[data-testid="expiry-date-icon"]')
      end
    end

    context 'and is near expiry' do
      let_it_be(:expiry_date) { 1.day.since.to_date.to_s }
      let_it_be(:credential) { create(:personal_access_token, user: user, expires_at: expiry_date) }

      it 'shows the correct date' do
        expect(rendered).to have_text(expiry_date)
      end

      it 'has an icon' do
        expect(rendered).to match(/<use href=".+?icons-.+?#warning">/)
      end
    end

    context 'and has expired' do
      let_it_be(:expiry_date) { 2.days.ago.to_date.to_s }
      let_it_be(:credential) { create(:personal_access_token, user: user, expires_at: expiry_date) }

      it 'shows the correct date' do
        expect(rendered).to have_text(expiry_date)
      end

      it 'has an icon' do
        expect(rendered).to match(/<use href=".+?icons-.+?#error">/)
      end
    end
  end
end
