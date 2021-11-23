# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Session TTLs' do
  include SessionHelpers

  RSpec.shared_examples_for 'session ttls' do
    it 'creates a session with a short TTL when login fails' do
      visit new_user_session_path
      # The session key only gets created after a post
      fill_in 'user_login', with: 'non-existant@gitlab.org'
      fill_in 'user_password', with: '12345678'
      click_button 'Sign in'

      expect(page).to have_content('Invalid login or password')

      expect_single_session_with_short_ttl(redis_store_class)
    end

    it 'increases the TTL when the login succeeds' do
      user = create(:user)
      gitlab_sign_in(user)

      expect(page).to have_content(user.name)

      expect_single_session_with_authenticated_ttl(redis_store_class)
    end

    context 'with an unauthorized project' do
      let_it_be(:project) { create(:project, :repository) }

      it 'creates a session with a short TTL' do
        visit project_raw_path(project, 'master/README.md')

        expect_single_session_with_short_ttl(redis_store_class)
        expect(page).to have_current_path(new_user_session_path)
      end
    end
  end

  it_behaves_like 'redis sessions store', 'session ttls'
end
