# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::Users', feature_category: :user_profile do
  include Spec::Support::Helpers::Features::AdminUsersHelpers
  include Spec::Support::Helpers::ModalHelpers

  describe 'password complexity', :js do
    let!(:user) { create(:user) }
    let!(:admin) { create(:admin) }
    let(:path_to_visit) { edit_admin_user_path(user) }
    let(:password_input_selector) { :user_password }
    let(:submit_button_selector) { _('Save changes') }

    before do
      sign_in(admin)
      gitlab_enable_admin_mode_sign_in(admin)
    end

    it 'does not render any rule' do
      visit path_to_visit

      expect(page).not_to have_selector('[data-testid="password-rule-text"]')
    end

    context 'when all password complexity rules are enabled' do
      include_context 'with all password complexity rules enabled'
      let(:password) { '12345aA.' }

      it 'updates user password' do
        visit path_to_visit

        expect(page).to have_selector('[data-testid="password-rule-text"]', count: 0)

        fill_in :user_password, with: password
        fill_in :user_password_confirmation, with: password

        expect(page).to have_selector('[data-testid="password-rule-text"]', count: 4)

        click_button submit_button_selector

        expect(page).to have_content(_('User was successfully updated.'))
        expect(page).to have_current_path(admin_user_path(user), ignore_query: true)
      end

      context 'without filling password' do
        let(:new_user_name) { FFaker::Name.name }

        it 'allows admin to update user info' do
          visit path_to_visit

          expect(page).to have_selector('[data-testid="password-rule-text"]', count: 0)

          fill_in 'user_name', with: new_user_name
          click_button submit_button_selector

          expect(page).to have_content(_('User was successfully updated.'))
          expect(page).to have_content(new_user_name)
          expect(page).to have_current_path(admin_user_path(user), ignore_query: true)
        end
      end
    end
  end
end
