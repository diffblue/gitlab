# frozen_string_literal: true

require 'support/helpers/listbox_helpers'

module Features
  module TrialHelpers
    include ListboxHelpers

    def expect_to_be_on_group_page(path: 'gitlab')
      expect(page).to have_current_path("/#{path}?trial=true")
      expect(page).to have_link('Group information')
    end

    def expect_to_be_on_namespace_selection_with_errors
      expect_to_be_on_namespace_selection
      expect(page).to have_content('We have found the following errors')
      expect(page).to have_content('_trial_fail_')
    end

    def expect_to_be_on_namespace_selection
      expect(page).to have_content('This subscription is for')
      expect(page).to have_content('Who will be using GitLab?')
    end

    def expect_to_be_on_lead_form_with_errors
      expect(page).to have_content('We have found the following errors')
      expect(page).to have_content('_lead_fail_')
      expect(page).to have_content('Number of employees')
    end

    def expect_to_be_on_group_security_dashboard(group_for_path: group)
      expect(page).to have_current_path(group_security_dashboard_path(group_for_path, { trial: true }))
      expect(page).to have_link('Group information')
    end

    def fill_in_trial_selection_form(from: 'Please select a group')
      select_from_listbox group.name, from: from
      choose :trial_entity_company
    end

    def fill_in_trial_form_for_new_group(name: 'gitlab', glm_source: nil)
      fill_in 'new_group_name', with: name
      choose :trial_entity_company if glm_source != 'about.gitlab.com'
    end

    def form_data
      {
        phone_number: '+1 23 456-78-90',
        company_size: '1 - 99',
        company_name: 'GitLab',
        country: { id: 'US', name: 'United States of America' },
        state: { id: 'CA', name: 'California' }
      }
    end

    def fill_in_company_information
      fill_in 'company_name', with: form_data[:company_name]
      select form_data[:company_size], from: 'company_size'
      fill_in 'phone_number', with: form_data[:phone_number]
      select form_data.dig(:country, :name), from: 'country'
      select form_data.dig(:state, :name), from: 'state'
    end

    def submit_company_information_form(lead_success: true, trial_success: true, with_trial: false, extra_params: {})
      # lead
      trial_user_params = {
        company_name: form_data[:company_name],
        company_size: form_data[:company_size].delete(' '),
        first_name: user.first_name,
        last_name: user.last_name,
        phone_number: form_data[:phone_number],
        country: form_data.dig(:country, :id),
        work_email: user.email,
        uid: user.id,
        setup_for_company: user.setup_for_company,
        skip_email_confirmation: true,
        gitlab_com_trial: true,
        provider: 'gitlab',
        newsletter_segment: user.email_opted_in,
        state: form_data.dig(:state, :id)
      }.merge(extra_params)

      lead_params = {
        trial_user: trial_user_params
      }

      lead_result = if lead_success
                      ServiceResponse.success
                    else
                      ServiceResponse.error(message: '_lead_fail_')
                    end

      expect_next_instance_of(GitlabSubscriptions::CreateLeadService) do |service|
        expect(service).to receive(:execute).with(lead_params).and_return(lead_result)
      end

      # trial
      if with_trial
        stub_apply_trial(
          namespace_id: group.id,
          success: trial_success,
          extra_params: extra_params.merge(existing_group_attrs)
        )
      end

      click_button 'Continue'

      wait_for_requests
    end

    def submit_trial_selection_form(success: true, extra_params: {})
      stub_apply_trial(
        namespace_id: group.id,
        success: success,
        extra_params: extra_with_glm_source(extra_params).merge(existing_group_attrs)
      )

      click_button 'Start your free trial'
    end

    def submit_new_group_trial_selection_form(success: true, extra_params: {})
      stub_apply_trial(success: success, extra_params: extra_with_glm_source(extra_params))

      click_button 'Start your free trial'
    end

    def extra_with_glm_source(extra_params)
      extra_params[:trial_entity] = 'company' unless extra_params[:glm_source] == 'about.gitlab.com'

      extra_params
    end

    def existing_group_attrs
      { namespace: group.slice(:id, :name, :path, :kind, :trial_ends_on) }
    end

    def new_group_attrs(path: 'gitlab')
      {
        namespace: {
          id: anything,
          path: path,
          name: 'gitlab',
          kind: 'group',
          trial_ends_on: nil
        }
      }
    end

    def stub_apply_trial(namespace_id: anything, success: true, extra_params: {})
      trial_user_params = {
        namespace_id: namespace_id,
        gitlab_com_trial: true,
        sync_to_gl: true
      }.merge(extra_params)

      service_params = {
        trial_user_information: trial_user_params,
        uid: user.id
      }

      trial_success = if success
                        ServiceResponse.success
                      else
                        ServiceResponse.error(message: '_trial_fail_')
                      end

      expect_next_instance_of(GitlabSubscriptions::Trials::ApplyTrialService, service_params) do |instance|
        expect(instance).to receive(:execute).and_return(trial_success)
      end
    end
  end
end
