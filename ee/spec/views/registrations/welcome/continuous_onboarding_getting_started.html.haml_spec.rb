# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'registrations/welcome/continuous_onboarding_getting_started' do
  describe 'project import state' do
    let_it_be(:project) { create(:project) }

    subject { rendered }

    before do
      allow(view).to receive(:project).and_return(project)
      allow(view).to receive(:track_label).and_return('free_registration')
      allow(view).to receive(:learn_gitlab_onboarding_available?).and_return(project_available)

      render
    end

    context 'when onboarding project is ready' do
      let_it_be(:project_available) { true }

      it { is_expected.to have_content("Ok, let's go") }
      it { is_expected.not_to have_content('Creating your onboarding experience...') }
      it { is_expected.to have_css("[data-track-label='free_registration']") }
      it { is_expected.to have_css("[data-track-action='click_ok_lets_go']") }

      it 'does not have meta refresh tag' do
        expect(view.content_for(:meta_tags)).to be_nil
      end
    end

    context 'when onboarding project is not yet ready' do
      let_it_be(:project_available) { false }

      it { is_expected.not_to have_content("Ok, let's go") }
      it { is_expected.to have_content('Creating your onboarding experience...') }
      it { is_expected.not_to have_css("[data-track-label='free_registration']") }
      it { is_expected.not_to have_css("[data-track-action='click_ok_lets_go']") }

      it 'has meta refresh tag' do
        expect(view.content_for(:meta_tags)).to include("<meta content=\"5\" http-equiv=\"refresh\">")
      end
    end
  end
end
