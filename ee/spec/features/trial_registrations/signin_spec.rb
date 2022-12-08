# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Trial Sign In', feature_category: :purchase do
  let(:user) { create(:user) }

  describe 'on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true).at_least(:once)
    end

    it 'logs the user in' do
      url_params = { glm_source: 'any-source', glm_content: 'any-content' }
      visit(new_trial_registration_path(url_params))

      click_on 'Sign in'

      within('div#login-pane') do
        fill_in 'user_login', with: user.email
        fill_in 'user_password', with: user.password

        click_button 'Sign in'
      end

      expect(current_url).to eq(new_trial_url(url_params))
    end
  end

  describe 'not on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com?).and_return(false).at_least(:once)
    end

    it 'returns 404' do
      visit(new_trial_registration_path)

      expect(status_code).to eq(404)
    end
  end
end
