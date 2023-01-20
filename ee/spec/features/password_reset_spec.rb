# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Password reset', feature_category: :user_profile do
  describe 'password complexity', :js do
    let_it_be(:user) { create(:user) }

    let(:path_to_visit) { edit_user_password_path(reset_password_token: user.send_reset_password_instructions) }
    let(:password_input_selector) { :user_password }
    let(:submit_button_selector) { _('Change your password') }

    before do
      sign_in(user)
    end

    it_behaves_like 'password complexity validations'

    context 'when all password complexity rules are enabled' do
      include_context 'with all password complexity rules enabled'

      context 'when all rules are matched' do
        let(:password) { '12345aA.' }

        it 'resets password' do
          visit path_to_visit

          expect(page).to have_selector('[data-testid="password-rule-text"]', count: 4)

          fill_in :user_password, with: password
          fill_in :user_password_confirmation, with: password

          click_button submit_button_selector

          expect(page).to have_content(I18n.t('devise.passwords.updated_not_active'))
          expect(page).to have_current_path new_user_session_path, ignore_query: true
        end
      end
    end
  end
end
