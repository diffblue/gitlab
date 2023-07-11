# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GitLab Duo Chat', :js, feature_category: :global_search do
  let_it_be(:user) { create(:user) }

  before do
    allow(License).to receive(:feature_available?).and_return(true)

    allow(user).to receive(:use_new_navigation).and_return(true)
    sign_in(user)
  end

  describe 'Feature enabled and available' do
    before do
      visit root_path
    end

    shared_examples 'GitLab Duo drawer' do
      it 'opens the drawer to chat with GitLab Duo' do
        wait_for_requests

        page.within '[data-testid="chat-component"]' do
          expect(page).to have_text('GitLab Duo Chat')
        end
      end
    end

    context "when opening the drawer from the help center" do
      before do
        page.within '[data-testid="super-sidebar"]' do
          click_button('Help')
          click_button('Ask GitLab Duo')
        end
      end

      it_behaves_like 'GitLab Duo drawer'
    end

    context "when opening the drawer from the breadcrumbs" do
      before do
        page.within '[data-testid="top-bar"]' do
          click_button('Ask GitLab Duo')
        end
      end

      it_behaves_like 'GitLab Duo drawer'
    end
  end

  context 'when the :tanuki_bot_breadcrumbs_entry_point feature flag is off' do
    before do
      stub_feature_flags(tanuki_bot_breadcrumbs_entry_point: false)
      visit root_path
    end

    it 'does not show the entry point in the breadcrumbs' do
      page.within '[data-testid="top-bar"]' do
        expect(page).not_to have_button('Ask GitLab Duo')
      end
    end
  end
end
