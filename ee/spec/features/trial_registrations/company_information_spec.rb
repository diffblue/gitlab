# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Company Information', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:fields) { ['Company Name', 'Number of employees', 'Country', 'Telephone Number (Optional)', 'Website (Optional)', 'GitLab Ultimate trial (Optional)'] }

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
    before do
      expect_next_instance_of(GitlabSubscriptions::CreateLeadService) do |service|
        expect(service).to receive(:execute).and_return(success: true)
      end
    end

    it 'with all required fields' do
      fill_in 'company_name', with: 'GitLab'
      select '1 - 99', from: 'company_size'
      select 'United States of America', from: 'country'

      click_button 'Continue'
    end

    # TODO: Logic for input validation and end-to-end once trials_controller has a corresponding endpoint
  end
end
