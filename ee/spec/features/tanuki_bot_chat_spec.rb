# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Tanuki Bot Chat', :js, feature_category: :global_search do
  let_it_be(:user) { create(:user) }

  describe 'Feature enabled and available' do
    before do
      allow(License).to receive(:feature_available?).and_return(true)

      allow(user).to receive(:use_new_navigation).and_return(true)
      sign_in(user)

      visit root_path
    end

    it 'opens a chat drawer to chat with Tanuki Bot' do
      page.within '[data-testid="super-sidebar"]' do
        click_button('Help')
        click_button('Ask the Tanuki Bot')
      end

      wait_for_requests

      page.within '[data-testid="tanuki-bot-chat-drawer"]' do
        expect(page).to have_text('Tanuki Bot')
      end
    end
  end
end
