# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Password', feature_category: :user_profile do
  let_it_be(:user) { create(:user) }

  def save_user_new_password
    visit path_to_visit

    fill_in :user_password, with: user.password
    fill_in :user_new_password, with: password
    fill_in :user_password_confirmation, with: password

    click_button submit_button_selector
  end

  shared_examples 'set a new password' do
    it_behaves_like 'password complexity validations'

    context 'when all password complexity rules are enabled' do
      include_context 'with all password complexity rules enabled'

      context 'when all rules are matched' do
        let(:password) { '12345aA.' }

        it 'resets password' do
          save_user_new_password

          page.within '.flash-container' do
            expect(page).to have_content(flash_message)
          end
        end
      end
    end
  end

  describe 'password complexity', :js do
    before do
      sign_in(user)
    end

    context 'when on user profile page' do
      let(:path_to_visit) { edit_profile_password_path }
      let(:password_input_selector) { :user_new_password }
      let(:submit_button_selector) { _('Save password') }
      let(:flash_message) { _('Password was successfully updated. Please sign in again.') }

      it_behaves_like 'set a new password'
    end

    context 'when on user setting new password page' do
      let(:path_to_visit) { new_profile_password_path }
      let(:password_input_selector) { :user_new_password }
      let(:submit_button_selector) { _('Set new password') }
      let(:flash_message) { _('Password successfully changed') }

      it_behaves_like 'set a new password'
    end
  end
end
