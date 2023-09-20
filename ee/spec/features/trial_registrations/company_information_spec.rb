# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Company Information', :js, :saas, feature_category: :activation do
  include SaasRegistrationHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:fields) do
    [
      'First Name',
      'Last Name',
      'Company Name',
      'Number of employees',
      'Country',
      'Telephone number (optional)',
      'Website (optional)',
      'GitLab Ultimate trial (optional)'
    ]
  end

  before do
    sign_in(user)
    visit new_users_sign_up_company_path
  end

  it 'shows the expected fields' do
    fields.each { |field| expect(page).to have_content(field) }
  end

  context 'with company information to create lead concerns' do
    using RSpec::Parameterized::TableSyntax

    let(:extra_params) { {} }
    let(:params) do
      {
        first_name: user.first_name,
        last_name: user.last_name,
        company_name: 'Test Company',
        company_size: '1-99',
        phone_number: '+1234567890',
        country: 'US',
        state: 'FL',
        website_url: 'https://gitlab.com',
        trial_onboarding_flow: 'false'
      }.merge(extra_params)
    end

    where(:service_response, :current_path, :page_content) do
      ServiceResponse.success                   | new_users_sign_up_group_path | 'Create or import your first project'
      ServiceResponse.error(message: 'failed')  | users_sign_up_company_path   | 'failed'
    end

    with_them do
      it 'verifies existing name fields filled and redirects to correct path' do
        expect(page.find_field('first_name').value).to eq user.first_name
        expect(page.find_field('last_name').value).to eq user.last_name

        fill_company_form_fields

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

    context 'when first and last name are entered by the user' do
      let(:extra_params) { { first_name: 'Foo', last_name: 'Bar' } }

      it 'ensures the required fields for name are entered' do
        fill_in 'first_name', with: ''
        fill_in 'last_name', with: ''

        click_button 'Continue'

        expect(page).to have_native_text_validation_message('first_name')
        expect(page).to have_native_text_validation_message('last_name')

        fill_in 'first_name', with: 'Foo'
        fill_in 'last_name', with: 'Bar'
        fill_company_form_fields

        expect_next_instance_of(
          GitlabSubscriptions::CreateTrialOrLeadService,
          user: user,
          params: ActionController::Parameters.new(params).permit!
        ) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.success)
        end

        click_button 'Continue'

        expect(page).to have_current_path(new_users_sign_up_group_path, ignore_query: true)
        expect(page).to have_content('Create or import your first project')
      end
    end
  end
end
