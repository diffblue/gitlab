# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'registrations/welcome/show' do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(Gitlab).to receive(:com?).and_return(true)
  end

  describe 'forms and progress bar' do
    let_it_be(:user_other_role_details_enabled) { false }
    let_it_be(:stubbed_experiments) { {} }

    before do
      allow(view).to receive(:redirect_path).and_return(redirect_path)
      allow(view).to receive(:signup_onboarding_enabled?).and_return(signup_onboarding_enabled)
      stub_feature_flags(user_other_role_details: user_other_role_details_enabled)
      stub_experiments(stubbed_experiments)

      render
    end

    subject { rendered }

    where(:redirect_path, :signup_onboarding_enabled, :show_progress_bar, :flow, :is_continue) do
      '/-/subscriptions/new'    | false | true  | :subscription | true
      '/-/subscriptions/new'    | true  | true  | :subscription | true
      '/-/trials/new'           | false | false | :trial        | true
      '/-/trials/new'           | true  | false | :trial        | true
      '/oauth/authorize/abc123' | false | false | nil           | false
      '/oauth/authorize/abc123' | true  | false | nil           | false
      nil                       | false | false | nil           | false
      nil                       | true  | true  | nil           | true
    end

    with_them do
      it 'shows the correct text for the :setup_for_company label' do
        expected_text = "Who will be using #{flow.nil? ? 'GitLab' : "this GitLab #{flow}"}?"

        is_expected.to have_selector('label[for="user_setup_for_company"]', text: expected_text)
      end

      it 'shows the correct text for the submit button' do
        expected_text = is_continue ? 'Continue' : 'Get started!'

        is_expected.to have_button(expected_text)
      end

      it { is_expected_to_have_progress_bar(status: show_progress_bar) }

      context 'feature flag other_role_details is enabled' do
        let_it_be(:user_other_role_details_enabled) { true }

        it 'has a text field for other role' do
          is_expected.not_to have_selector('input[type="hidden"][name="user[other_role]"]', visible: false)
          is_expected.to have_selector('input[type="text"][name="user[other_role]"]')
        end
      end

      context 'experiment(:jobs_to_be_done)' do
        let_it_be(:stubbed_experiments) { { jobs_to_be_done: :candidate } }

        it 'renders a select and text field for additional information' do
          is_expected.to have_selector('select[name="jobs_to_be_done"]')
          is_expected.to have_selector('input[name="jobs_to_be_done_other"]', visible: false)
        end
      end
    end
  end

  def is_expected_to_have_progress_bar(status: true)
    allow(view).to receive(:show_signup_flow_progress_bar?).and_return(status)

    if status
      is_expected.to have_selector('#progress-bar')
    else
      is_expected.not_to have_selector('#progress-bar')
    end
  end

  context 'rendering the hidden email opt in checkbox' do
    subject { render }

    it { is_expected.to have_selector('input[name="user[email_opted_in]"]') }
    it { is_expected.to have_css('.js-email-opt-in.hidden') }
  end
end
