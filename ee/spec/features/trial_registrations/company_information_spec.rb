# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Company Information', :js, feature_category: :experimentation_adoption do
  let_it_be(:user) { create(:user) }
  let_it_be(:fields) { ['Company Name', 'Number of employees', 'Country', 'Telephone number (optional)', 'Website (optional)', 'GitLab Ultimate trial (optional)'] }

  before do
    allow(Gitlab).to receive(:com?).and_return(true).at_least(:once)
    sign_in(user)
    visit new_users_sign_up_company_path

    expect(page).to have_content('About your company')
  end

  it 'shows the expected fields' do
    fields.each { |field| expect(page).to have_content(field) }
  end

  context 'send company information to create lead' do
    using RSpec::Parameterized::TableSyntax

    let(:params) do
      {
        company_name: 'GitLab',
        company_size: '1-99',
        phone_number: '+1 23 456-78-90',
        country: 'US',
        state: 'CA',
        website_url: 'gitlab.com',
        trial_onboarding_flow: 'false'
      }
    end

    where(:service_response, :current_path, :page_content) do
      ServiceResponse.success                   | new_users_sign_up_groups_project_path | 'Create or import your first project'
      ServiceResponse.error(message: 'failed')  | users_sign_up_company_path            | 'failed'
    end

    with_them do
      it 'redirects to correct path' do
        fill_in 'company_name', with: 'GitLab'
        select '1 - 99', from: 'company_size'
        select 'United States of America', from: 'country'
        select 'California', from: 'state'
        fill_in 'website_url', with: 'gitlab.com'
        fill_in 'phone_number', with: '+1 23 456-78-90'

        expect_next_instance_of(
          GitlabSubscriptions::CreateTrialOrLeadService,
          user: user,
          params: ActionController::Parameters.new(params).permit!
        ) do |service|
          expect(service).to receive(:execute).and_return(service_response)
        end

        click_button 'Continue'

        expect(page).to have_current_path(current_path, ignore_query: true)
        expect(page).to have_content(page_content)
      end
    end
  end
end
