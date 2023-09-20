# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GitLab.com Google Analytics DataLayer', :js, feature_category: :application_instrumentation do
  include JavascriptFormHelper

  let(:google_tag_manager_id) { 'GTM-WWKMTWS' }
  let(:new_user) { build(:user) }
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

        fill_in_sign_up_form(new_user, 'Continue')

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

        fill_in_sign_up_form(new_user)

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
      visit new_trial_path(step: GitlabSubscriptions::Trials::CreateService::TRIAL)

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
