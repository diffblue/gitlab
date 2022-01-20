# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Trial Capture Lead', :js do
  let_it_be(:user) { create(:user) }

  before do
    allow(Gitlab).to receive(:com?).and_return(true).at_least(:once)
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

      expect_any_instance_of(GitlabSubscriptions::CreateLeadService).to receive(:execute).with(lead_params) do
        { success: true }
      end
    end

    context 'with state' do
      it 'proceeds to the next step' do
        fill_in 'company_name', with: form_data[:company_name]
        select form_data[:company_size], from: 'company_size'
        fill_in 'phone_number', with: form_data[:phone_number]
        select form_data.dig(:country, :name), from: 'country'
        select form_data.dig(:state, :name), from: 'state'

        click_button 'Continue'

        expect(page).not_to have_css('flash-container')
        expect(current_path).to eq(select_trials_path)
      end
    end

    context 'without state' do
      let(:country) { { id: 'AF', name: 'Afghanistan' } }
      let(:extra_trial_params) { {} }

      it 'proceeds to the next step' do
        fill_in 'company_name', with: form_data[:company_name]
        select form_data[:company_size], from: 'company_size'
        fill_in 'phone_number', with: form_data[:phone_number]
        select form_data.dig(:country, :name), from: 'country'

        expect(page).not_to have_selector('[data-testid="state"]')

        click_button 'Continue'

        expect(page).not_to have_css('flash-container')
        expect(current_path).to eq(select_trials_path)
      end
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
        expect(current_path).to eq(new_trial_path)
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
          expect(current_path).to eq(new_trial_path)
        end
      end
    end

    def phone_validation_message
      page.find('[data-testid="phone_number"]').native.attribute('validationMessage')
    end
  end
end
