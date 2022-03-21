# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Company Information', :js do
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
    it 'with all required fields' do
      trial_user_params = {
        "company_name" => 'GitLab',
        "company_size" => '1 - 99'.delete(' '),
        "phone_number" => '+1 23 456-78-90',
        "country" => 'US',
        "state" => '',
        "work_email" => user.email,
        "uid" => user.id,
        "setup_for_company" => user.setup_for_company,
        "skip_email_confirmation" => true,
        "gitlab_com_trial" => true,
        "provider" => "gitlab",
        "newsletter_segment" => user.email_opted_in,
        "website_url" => 'gitlab.com'
      }

      lead_params = {
        trial_user: ActionController::Parameters.new(trial_user_params).permit!
      }

      fill_in 'company_name', with: 'GitLab'
      select '1 - 99', from: 'company_size'
      select 'United States of America', from: 'country'
      fill_in 'website_url', with: 'gitlab.com'
      fill_in 'phone_number', with: '+1 23 456-78-90'

      expect_next_instance_of(GitlabSubscriptions::CreateLeadService) do |service|
        expect(service).to receive(:execute).with(lead_params).and_return({ success: true })
      end

      click_button 'Continue'
    end
  end
end
