# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Trial lead submission and creation', :saas, :js, feature_category: :purchase do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
    visit new_trial_path

    wait_for_requests
  end

  context 'with valid company information' do
    let(:country) { { id: 'US', name: 'United States of America' } }
    let(:extra_trial_params) { { "state" => form_data.dig(:state, :id) } }
    let(:form_data) do
      {
        phone_number: '+1 23 456-78-90',
        company_size: '1 - 99',
        company_name: 'GitLab',
        country: country,
        state: { id: 'CA', name: 'California' }
      }
    end

    before do
      trial_user_params = {
        "company_name" => form_data[:company_name],
        "company_size" => form_data[:company_size].delete(' '),
        "first_name" => user.first_name,
        "last_name" => user.last_name,
        "phone_number" => form_data[:phone_number],
        "country" => form_data.dig(:country, :id),
        "work_email" => user.email,
        "uid" => user.id,
        "setup_for_company" => user.setup_for_company,
        "skip_email_confirmation" => true,
        "gitlab_com_trial" => true,
        "provider" => "gitlab",
        "newsletter_segment" => user.email_opted_in
      }.merge(extra_trial_params)

      lead_params = {
        trial_user: ActionController::Parameters.new(trial_user_params).permit!
      }

      expect_next_instance_of(GitlabSubscriptions::CreateLeadService) do |service|
        expect(service).to receive(:execute).with(lead_params).and_return(ServiceResponse.success) # rubocop:disable RSpec/ExpectInHook
      end
    end

    context 'when there is one trialable namespace' do
      context 'when applying trial fails' do
        before do
          create(:group).tap { |record| record.add_owner(user) }
          allow_next_instance_of(GitlabSubscriptions::Trials::ApplyTrialService) do |service|
            allow(service).to receive(:execute).and_return(ServiceResponse.error(message: '_fail_'))
          end
        end

        it 'fills out form, submits and lands on select page' do
          fill_in_company_information

          click_button 'Continue'

          expect(page).to have_current_path(create_lead_trials_path, ignore_query: true)
          expect(page).to have_content('We have found the following errors')
          expect(page).to have_content('This subscription is for')
        end
      end
    end

    context 'when there is more than one trialable namespace' do
      before do
        create(:group).tap { |record| record.add_owner(user) }
        create(:group).tap { |record| record.add_owner(user) }
      end

      it 'fills out the trial form and lands on the select namespace page' do
        fill_in_company_information

        click_button 'Continue'

        expect(page).to have_current_path(select_trials_path, ignore_query: true)
        expect(page).to have_content('This subscription is for')
      end
    end

    context 'with state' do
      it 'proceeds to the next step' do
        fill_in_company_information

        click_button 'Continue'

        expect(page).to have_current_path(select_trials_path, ignore_query: true)
        expect(page).to have_content('New Group Name')
      end
    end

    context 'without state' do
      let(:country) { { id: 'AF', name: 'Afghanistan' } }
      let(:extra_trial_params) { {} }

      it 'proceeds to the next step' do
        fill_in_company_information(with_state: false)

        expect(page).not_to have_selector('[data-testid="state"]')

        click_button 'Continue'

        expect(page).to have_current_path(select_trials_path, ignore_query: true)
      end
    end

    def fill_in_company_information(with_state: true)
      fill_in 'company_name', with: form_data[:company_name]
      select form_data[:company_size], from: 'company_size'
      fill_in 'phone_number', with: form_data[:phone_number]
      select form_data.dig(:country, :name), from: 'country'
      select form_data.dig(:state, :name), from: 'state' if with_state
    end
  end

  context 'with phone number validations' do
    before do
      fill_in 'company_name', with: 'GitLab'
      select '1 - 99', from: 'company_size'
      select 'United States of America', from: 'country'
    end

    context 'without phone number' do
      it 'shows validation error' do
        click_button 'Continue'

        expect(phone_validation_message).to eq('Please fill out this field.')
        expect(page).to have_current_path(new_trial_path, ignore_query: true)
      end
    end

    context 'with invalid phone number format' do
      it 'shows validation error' do
        invalid_phone_numbers = [
          '+1 (121) 22-12-23',
          '+12190AX ',
          'Tel:129120',
          '11290+12'
        ]

        invalid_phone_numbers.each do |phone_number|
          fill_in 'phone_number', with: phone_number

          click_button 'Continue'

          expect(phone_validation_message).to eq('Please match the requested format.')
          expect(page).to have_current_path(new_trial_path, ignore_query: true)
        end
      end
    end

    def phone_validation_message
      page.find('[data-testid="phone_number"]').native.attribute('validationMessage')
    end
  end
end
