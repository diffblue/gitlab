# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/learn_gitlab/onboarding', feature_category: :onboarding do
  describe 'project import state' do
    let(:project) { build(:project) }

    subject { rendered }

    before do
      assign(:project, project)
      assign(:track_label, 'free_registration')
      allow(view).to receive(:track_label).and_return('free_registration')

      render
    end

    it { is_expected.to have_content("Ok, let's go") }
    it { is_expected.not_to have_content('Creating your onboarding experience...') }
    it { is_expected.to have_css("[data-track-label='free_registration']") }
    it { is_expected.to have_css("[data-track-action='click_ok_lets_go']") }
  end
end
