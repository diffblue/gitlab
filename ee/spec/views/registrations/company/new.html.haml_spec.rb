# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'registrations/company/new', feature_category: :onboarding do
  describe 'Google Tag Manager' do
    let!(:gtm_id) { 'GTM-WWKMTWS' }
    let!(:google_url) { 'www.googletagmanager.com' }

    subject { rendered }

    before do
      stub_devise
      allow(Gitlab).to receive(:com?).and_return(true)
      stub_config(extra: { google_tag_manager_id: gtm_id, google_tag_manager_nonce_id: gtm_id })
      allow(view).to receive(:google_tag_manager_enabled?).and_return(gtm_enabled)

      render
    end

    describe 'when Google Tag Manager is enabled' do
      let(:gtm_enabled) { true }

      it { is_expected.to match(/#{google_url}/) }
    end

    describe 'when Google Tag Manager is disabled' do
      let(:gtm_enabled) { false }

      it { is_expected.not_to match(/#{google_url}/) }
    end
  end

  describe 'automatic_trial_registration experiment' do
    it "when user is coming from trial registration, it renders the control experience" do
      stub_experiments(automatic_trial_registration: true)
      allow(view).to receive(:trial_selected?).and_return(true)

      render

      expect_to_see_control
    end

    it 'renders the control experience' do
      stub_experiments(automatic_trial_registration: :control)

      render

      expect_to_see_control
    end

    it 'renders the candidate experience' do
      stub_experiments(automatic_trial_registration: :candidate)

      render

      expect(rendered).to have_content('About your company')
      expect(rendered).to have_content('Invite unlimited colleagues')
      expect(rendered).to have_content('Used by more than 100,000 organizations from around the globe:')
    end
  end

  def stub_devise
    allow(view).to receive(:devise_mapping).and_return(Devise.mappings[:user])
    allow(view).to receive(:resource).and_return(spy)
    allow(view).to receive(:resource_name).and_return(:user)
  end

  def expect_to_see_control
    expect(rendered).to have_content('About your company')
    expect(rendered).not_to have_content('Invite unlimited colleagues')
    expect(rendered).not_to have_content('Used by more than 100,000 organizations from around the globe:')
  end
end
