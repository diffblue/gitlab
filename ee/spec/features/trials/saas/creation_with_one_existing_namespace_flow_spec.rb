# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Trial lead submission and creation with one eligible namespace', :saas, :js, feature_category: :purchase do
  include Features::TrialHelpers

  let_it_be(:user) { create(:user) } # rubocop:disable Gitlab/RSpec/AvoidSetup
  let_it_be(:group) { create(:group, name: 'gitlab').tap { |record| record.add_owner(user) } } # rubocop:disable Gitlab/RSpec/AvoidSetup

  context 'when creating lead and applying trial is successful' do
    it 'fills out form, submits and lands on the group page' do
      sign_in(user)

      visit new_trial_path

      fill_in_company_information

      submit_company_information_form(with_trial: true)

      expect_to_be_on_group_page
    end

    context 'when part of the discover security flow' do
      it 'fills out form, submits and lands on the group security dashboard page' do
        sign_in(user)

        visit new_trial_path(glm_content: 'discover-group-security')

        fill_in_company_information

        submit_company_information_form(with_trial: true, extra_params: { glm_content: 'discover-group-security' })

        expect_to_be_on_group_security_dashboard
      end
    end
  end

  context 'when applying lead fails' do
    it 'fills out form, submits and sent back to information form with errors and is then resolved' do
      # setup
      sign_in(user)

      visit new_trial_path

      fill_in_company_information

      # lead failure
      submit_company_information_form(lead_success: false)

      expect_to_be_on_lead_form_with_errors

      # success
      submit_company_information_form(with_trial: true)

      expect_to_be_on_group_page
    end
  end

  context 'when applying trial fails' do
    it 'fills out form, submits and is sent to select namespace with errors and is then resolved' do
      # setup
      sign_in(user)

      visit new_trial_path

      fill_in_company_information

      # trial failure
      submit_company_information_form(with_trial: true, trial_success: false)

      expect_to_be_on_namespace_selection_with_errors

      # success
      fill_in_trial_selection_form(from: group.name)

      submit_trial_selection_form

      expect_to_be_on_group_page
    end

    it 'fails submitting trial and then chooses to create a namespace and apply trial to it' do
      # setup
      sign_in(user)

      visit new_trial_path

      fill_in_company_information

      # trial failure
      submit_company_information_form(with_trial: true, trial_success: false)

      expect_to_be_on_namespace_selection_with_errors

      # user pivots and decides to create a new group instead of using existing
      select_from_listbox 'Create group', from: 'gitlab'
      wait_for_requests

      fill_in_trial_form_for_new_group

      # success
      submit_new_group_trial_selection_form(extra_params: new_group_attrs(path: 'gitlab1'))

      expect_to_be_on_group_page(path: 'gitlab1')
    end
  end
end
