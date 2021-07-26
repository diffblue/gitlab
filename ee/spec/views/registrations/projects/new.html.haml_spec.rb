# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'registrations/projects/new' do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:project) { create(:project, namespace: namespace) }
  let_it_be(:trial_onboarding_flow) { false }
  let_it_be(:trial_during_signup_flow) { false }

  before do
    assign(:project, project)
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:in_trial_onboarding_flow?).and_return(trial_onboarding_flow)
    allow(view).to receive(:in_trial_during_signup_flow?).and_return(trial_during_signup_flow)
    allow(view).to receive(:import_sources_enabled?).and_return(false)

    render
  end

  it 'shows the progress bar' do
    expect(rendered).to have_selector('#progress-bar')
  end

  context 'in trial onboarding' do
    let_it_be(:trial_onboarding_flow) { true }

    it 'hides the progress bar in trial onboarding' do
      expect(rendered).not_to have_selector('#progress-bar')
    end

    it 'show the trial activation' do
      expect(rendered).to have_content('Congratulations, your free trial is activated.')
    end
  end

  context 'in trial flow' do
    let_it_be(:trial_during_signup_flow) { true }

    it 'show the trial activation' do
      expect(rendered).to have_content('Congratulations, your free trial is activated.')
    end
  end
end
