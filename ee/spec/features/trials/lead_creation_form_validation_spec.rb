# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Trial lead form submission and validation', :saas, :js, feature_category: :purchase do
  let_it_be(:user) { create(:user) }

  context 'with valid company information and without state' do
    let(:form_data) do
      {
        phone_number: '+1 23 456-78-90',
        company_size: '1 - 99',
        company_name: 'GitLab',
        country: { id: 'AF', name: 'Afghanistan' }
      }
    end

    let(:lead_params) do
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
      }

      { trial_user: ActionController::Parameters.new(trial_user_params).permit! }
    end

    it 'proceeds to the next step' do
      sign_in(user)

      visit new_trial_path

      fill_in_company_information

      expect(page).not_to have_selector('[data-testid="state"]')

      expect_next_instance_of(GitlabSubscriptions::CreateLeadService) do |service|
        expect(service).to receive(:execute).with(lead_params).and_return(ServiceResponse.success) # rubocop:disable RSpec/ExpectInHook
      end

      click_button 'Continue'

      expect(page).to have_content('Almost there')
      expect(page).to have_content('Who will be using GitLab?')
    end

    def fill_in_company_information
      fill_in 'company_name', with: form_data[:company_name]
      select form_data[:company_size], from: 'company_size'
      fill_in 'phone_number', with: form_data[:phone_number]
      select form_data.dig(:country, :name), from: 'country'
    end
  end
end
