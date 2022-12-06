# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GitLab.com Google Analytics DataLayer', :js, feature_category: :application_instrumentation do
  include JavascriptFormHelper

  let!(:google_tag_manager_id) { 'GTM-WWKMTWS' }
  let!(:user_attrs) { attributes_for(:user, first_name: 'GitLab', last_name: 'GitLab', company_name: 'GitLab', phone_number: '555-555-5555') }

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    allow(Gitlab).to receive(:com?).and_return(true)
    stub_application_setting(require_admin_approval_after_user_signup: false)
    stub_feature_flags(gitlab_gtm_datalayer: true)
    stub_config(extra: { google_tag_manager_id: google_tag_manager_id, google_tag_manager_nonce_id: google_tag_manager_id })
  end

  context 'on account sign up pages' do
    context 'when creating a new trial registration' do
      it 'tracks form submissions in the dataLayer' do
        visit new_trial_registration_path

        prevent_submit_for('#new_new_user')

        fill_in 'new_user_first_name', with: user_attrs[:first_name]
        fill_in 'new_user_last_name',  with: user_attrs[:last_name]
        fill_in 'new_user_username',   with: user_attrs[:username]
        fill_in 'new_user_email',      with: user_attrs[:email]
        fill_in 'new_user_password',   with: user_attrs[:password]

        click_button 'Continue'

        data_layer = execute_script('return window.dataLayer')
        last_event_in_data_layer = data_layer[-1]

        expect(last_event_in_data_layer["event"]).to eq("accountSubmit")
        expect(last_event_in_data_layer["accountType"]).to eq("freeThirtyDayTrial")
        expect(last_event_in_data_layer["accountMethod"]).to eq("form")
      end
    end

    context 'when creating a new user' do
      it 'track form submissions in the dataLayer' do
        visit new_user_registration_path

        prevent_submit_for('#new_new_user')

        fill_in 'new_user_first_name', with: user_attrs[:first_name]
        fill_in 'new_user_last_name',  with: user_attrs[:last_name]
        fill_in 'new_user_username',   with: user_attrs[:username]
        fill_in 'new_user_email',      with: user_attrs[:email]
        fill_in 'new_user_password',   with: user_attrs[:password]

        click_button 'Register'

        data_layer = execute_script('return window.dataLayer')
        last_event_in_data_layer = data_layer[-1]

        expect(last_event_in_data_layer["event"]).to eq("accountSubmit")
        expect(last_event_in_data_layer["accountType"]).to eq("standardSignUp")
        expect(last_event_in_data_layer["accountMethod"]).to eq("form")
      end
    end
  end

  context 'on trial group select page' do
    it 'tracks create group events' do
      sign_in user
      visit select_trials_path

      prevent_submit_for('.js-saas-trial-group')

      fill_in 'new_group_name', with: group.name
      find('#trial_entity_company').click
      click_button 'Start your free trial'

      data_layer = execute_script('return window.dataLayer')
      last_event_in_data_layer = data_layer[-1]

      expect(last_event_in_data_layer["event"]).to eq("saasTrialGroup")
    end
  end
end
