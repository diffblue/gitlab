# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::Users' do
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

    it_behaves_like 'password complexity validations'

    context 'when all password complexity rules are enabled' do
      include_context 'with all password complexity rules enabled'
      let(:password) { '12345aA.' }

      it 'updates user password' do
        visit path_to_visit

        expect(page).to have_selector('[data-testid="password-rule-text"]', count: 4)

        fill_in :user_password, with: password
        fill_in :user_password_confirmation, with: password

        click_button submit_button_selector

        expect(page).to have_content(_('User was successfully updated.'))
        expect(page).to have_current_path(admin_user_path(user), ignore_query: true)
      end
    end
  end
end
