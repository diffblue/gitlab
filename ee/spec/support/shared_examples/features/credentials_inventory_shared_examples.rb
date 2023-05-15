# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples_for 'credentials inventory personal access tokens' do
  let_it_be(:user) { defined?(managed_user) ? managed_user : create(:user, name: 'abc') }

  context 'when a personal access token is active' do
    context 'when default_pat_expiration feature flag is true' do
      before do
        create(:personal_access_token,
          user: user,
          created_at: '2019-12-10',
          updated_at: '2020-06-22',
          expires_at: nil)
        visit credentials_path
      end

      it 'shows the details', :aggregate_failures do
        expect(first_row.text).to include('abc')
        expect(first_row.text).to include('api')
        expect(first_row.text).to include('2019-12-10')
        expect(first_row.text).to include(PersonalAccessToken::MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS
          .days.from_now.strftime("%Y-%m-%d"))
        expect(first_row.text).not_to include('2020-06-22')
        expect(first_row).to have_selector('a.btn', text: 'Revoke')
      end
    end

    context 'when default_pat_expiration feature flag is false' do
      before do
        stub_feature_flags(default_pat_expiration: false)
        create(:personal_access_token,
          user: user,
          created_at: '2019-12-10',
          updated_at: '2020-06-22',
          expires_at: nil)
        visit credentials_path
      end

      it 'shows the details', :aggregate_failures do
        expect(first_row.text).to include('abc')
        expect(first_row.text).to include('api')
        expect(first_row.text).to include('2019-12-10')
        expect(first_row.text).to include('Never')
        expect(first_row.text).not_to include('2020-06-22')
        expect(first_row).to have_selector('a.btn', text: 'Revoke')
      end
    end
  end

  context 'when a personal access token has an expiry' do
    let_it_be(:expiry_date) { 1.day.since.to_date.to_s }

    before_all do
      create(
        :personal_access_token,
        user: user,
        created_at: '2019-12-10',
        updated_at: '2020-06-22',
        expires_at: expiry_date
      )
    end

    before do
      visit credentials_path
    end

    it 'shows the details with an expiry date' do
      expect(first_row.text).to include(expiry_date)
    end

    it 'has an expiry icon' do
      expect(first_row).to have_selector('[data-testid="expiry-date-icon"]')
    end
  end

  context 'when a personal access token is revoked' do
    before_all do
      create(:personal_access_token,
        :revoked,
        user: user,
        created_at: '2019-12-10',
        updated_at: '2020-06-22',
        expires_at: Time.zone.now)
    end

    before do
      visit credentials_path
    end

    it 'shows the details with a revoked date', :aggregate_failures do
      expect(first_row.text).to include('2020-06-22')
      expect(first_row).not_to have_selector('a.btn', text: 'Revoke')
    end
  end
end

RSpec.shared_examples_for 'credentials inventory SSH keys' do
  let_it_be(:user) { defined?(managed_user) ? managed_user : create(:user, name: 'abc') }

  context 'when a SSH key is active' do
    before_all do
      create(
        :personal_key,
        user: user,
        created_at: '2019-12-09',
        last_used_at: '2019-12-10',
        expires_at: nil
      )
    end

    before do
      visit credentials_path
    end

    it 'shows the details', :aggregate_failures do
      expect(first_row.text).to include('abc')
      expect(first_row.text).to include('2019-12-09')
      expect(first_row.text).to include('2019-12-10')
      expect(first_row.text).to include('Never')
    end

    it 'shows the delete button' do
      expect(first_row).to have_selector('.js-confirm-modal-button', text: _('Delete'))
    end

    context 'and the user clicks the delete button', :js do
      it 'deletes the key' do
        click_button('Delete')

        page.within('.modal') do
          page.click_button('Delete')
        end

        expect(page).to have_content('User key was successfully removed.')
        expect(page).to have_content('No credentials found')
      end
    end
  end

  context 'when a SSH key has an expiry' do
    let_it_be(:expiry_date) { 1.day.since.to_date.to_s }

    before_all do
      create(
        :personal_key,
        user: user,
        created_at: '2019-12-10',
        last_used_at: '2020-06-22',
        expires_at: expiry_date
      )
    end

    before do
      visit credentials_path
    end

    it 'shows the details with an expiry date' do
      expect(first_row.text).to include(expiry_date)
    end

    it 'has an expiry icon' do
      expect(first_row).to have_selector('[data-testid="expiry-date-icon"]')
    end
  end
end
