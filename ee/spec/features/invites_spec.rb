# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group or Project invitations', :js, feature_category: :onboarding do
  let(:group) { create(:group, name: 'Owned') }
  let(:project) { create(:project, :repository, namespace: group) }
  let(:group_invite) { create(:group_member, :invited, group: group) }
  let(:new_user) { build_stubbed(:user, email: group_invite.invite_email) }
  let(:com) { true }

  before do
    stub_feature_flags(arkose_labs_signup_challenge: false)
    stub_application_setting(require_admin_approval_after_user_signup: false)
    allow(::Gitlab).to receive(:com?).and_return(com)

    visit invite_path(group_invite.raw_invite_token)
  end

  def fill_in_sign_up_form(user)
    fill_in 'new_user_first_name', with: user.first_name
    fill_in 'new_user_last_name', with: user.last_name
    fill_in 'new_user_username', with: user.username
    fill_in 'new_user_email', with: user.email
    fill_in 'new_user_password', with: user.password

    wait_for_all_requests

    click_button 'Register'
  end

  context 'when on .com' do
    context 'without setup question' do
      it 'bypasses the setup_for_company question' do
        fill_in_sign_up_form(new_user)

        expect(find('input[name="user[setup_for_company]"]', visible: :hidden).value).to eq 'true'
        expect(page).not_to have_content('My company or team')
      end
    end

    context 'with setup question' do
      let(:new_user) {  build_stubbed(:user, email: 'bogus@me.com') }

      it 'has the setup question' do
        fill_in_sign_up_form(new_user)

        expect(page).to have_content('My company or team')
      end
    end
  end

  context 'when not on .com' do
    let(:com) { false }

    it 'bypasses the setup_for_company question' do
      fill_in_sign_up_form(new_user)

      expect(page).not_to have_content('My company or team')
    end
  end

  it_behaves_like 'creates a user with ArkoseLabs risk band' do
    let(:signup_path) { invite_path(group_invite.raw_invite_token) }
    let(:user_email) { new_user[:email] }

    subject(:fill_and_submit_signup_form) { fill_in_sign_up_form(new_user) }
  end
end
