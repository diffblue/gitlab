# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Trial lead submission and creation with multiple eligible namespaces', :saas_trial, :js, feature_category: :purchase do
  let_it_be(:user) { create(:user) } # rubocop:disable Gitlab/RSpec/AvoidSetup
  let_it_be(:group) do # rubocop:disable Gitlab/RSpec/AvoidSetup
    create(:group).tap { |record| record.add_owner(user) }
    create(:group, name: 'gitlab').tap { |record| record.add_owner(user) }
  end

  context 'when creating lead and applying trial is successful' do
    it 'fills out form, submits and lands on the group page' do
      sign_in(user)

      visit new_trial_path

      fill_in_company_information

      submit_company_information_form

      expect_to_be_on_namespace_selection

      fill_in_trial_selection_form

      submit_trial_selection_form

      expect_to_be_on_group_page
    end

    context 'when new trial is selected from within an existing namespace' do
      it 'fills out form, has the existing namespace preselected, submits and lands on the group page' do
        glm_params = { glm_source: '_glm_source_', glm_content: '_glm_content_' }

        sign_in(user)

        visit new_trial_path(namespace_id: group.id, **glm_params)

        fill_in_company_information

        submit_company_information_form(extra_params: glm_params)

        expect_to_be_on_namespace_selection

        fill_in_trial_selection_form(from: group.name)

        submit_trial_selection_form(extra_params: glm_params)

        expect_to_be_on_group_page
      end
    end

    context 'when part of the discover security flow' do
      it 'fills out form, submits and lands on the group security dashboard page' do
        sign_in(user)

        visit new_trial_path(glm_content: 'discover-group-security')

        fill_in_company_information

        submit_company_information_form(extra_params: { glm_content: 'discover-group-security' })

        expect_to_be_on_namespace_selection

        fill_in_trial_selection_form

        submit_trial_selection_form(extra_params: { glm_content: 'discover-group-security' })

        expect_to_be_on_group_security_dashboard
      end
    end
  end

  context 'when selecting to create a new group with an existing group name' do
    it 'fills out form, submits and lands on the group page with a unique path' do
      sign_in(user)

      visit new_trial_path

      fill_in_company_information

      submit_company_information_form

      expect_to_be_on_namespace_selection

      select_from_listbox 'Create group', from: 'Please select a group'
      wait_for_requests

      # success
      fill_in_trial_selection_form_for_new_group

      submit_new_group_trial_selection_form(extra_params: new_group_attrs(path: 'gitlab1'))

      expect_to_be_on_group_page(path: 'gitlab1')
    end
  end

  context 'when selecting to create a new group with an invalid group name' do
    it 'fills out form, submits and is presented with error then fills out valid name' do
      sign_in(user)

      visit new_trial_path

      fill_in_company_information

      submit_company_information_form

      expect_to_be_on_namespace_selection

      select_from_listbox 'Create group', from: 'Please select a group'
      wait_for_requests

      # namespace invalid check
      fill_in_trial_selection_form_for_new_group(name: '_invalid group name_')

      click_button 'Start your free trial'

      expect_to_have_namespace_creation_errors

      # success when choosing a valid name instead
      fill_in_trial_selection_form_for_new_group(name: 'valid')

      submit_new_group_trial_selection_form(extra_params: new_group_attrs(path: 'valid', name: 'valid'))

      expect_to_be_on_group_page(path: 'valid')
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
      submit_company_information_form

      expect_to_be_on_namespace_selection

      fill_in_trial_selection_form

      submit_trial_selection_form

      expect_to_be_on_group_page
    end
  end

  context 'when applying trial fails' do
    it 'fills out form, submits and is sent to select namespace with errors and is then resolved' do
      # setup
      sign_in(user)

      visit new_trial_path

      fill_in_company_information

      submit_company_information_form

      expect_to_be_on_namespace_selection

      fill_in_trial_selection_form

      # trial failure
      submit_trial_selection_form(success: false)

      expect_to_be_on_namespace_selection_with_errors

      # success
      fill_in_trial_selection_form(from: group.name)

      submit_trial_selection_form

      expect_to_be_on_group_page
    end
  end

  def fill_in_trial_selection_form_for_new_group(name: 'gitlab')
    within('[data-testid="trial-form"]') do
      expect(page).to have_text('New group name')
    end

    fill_in_trial_form_for_new_group(name: name, glm_source: nil)
  end
end
