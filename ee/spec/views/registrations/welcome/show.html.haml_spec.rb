# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'registrations/welcome/show', :saas, feature_category: :onboarding do
  let(:onboarding_status) do
    instance_double(
      ::Onboarding::Status, invite?: false, enabled?: true, subscription?: false, trial?: false, oauth?: false
    )
  end

  before do
    allow(view).to receive(:onboarding_status).and_return(onboarding_status)
    allow(view).to receive(:current_user).and_return(build_stubbed(:user))
    allow(view).to receive(:welcome_update_params).and_return({})
  end

  context 'with basic form items' do
    before do
      render
    end

    subject { rendered }

    it 'the text for the :setup_for_company label' do
      is_expected.to have_selector('label[for="user_setup_for_company"]', text: _('Who will be using GitLab?'))
    end

    it 'shows the correct text for the submit button' do
      is_expected.to have_button('Continue')
    end

    it { is_expected.to have_selector('#joining_project_true') }

    it 'renders a select and text field for additional information' do
      is_expected.to have_selector('select[name="user[registration_objective]"]')
      is_expected.to have_selector('input[name="jobs_to_be_done_other"]', visible: false)
    end
  end

  context 'for rendering the hidden email opt in checkbox' do
    subject { render }

    it { is_expected.to have_selector('input[name="user[email_opted_in]"]') }
    it { is_expected.to have_css('.js-email-opt-in.hidden') }
  end
end
