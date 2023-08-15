# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/learn_gitlab/onboarding', feature_category: :onboarding do
  let(:project) { build(:project) }
  let(:track_label) { 'free_registration' }
  let(:onboarding_status) { instance_double(::Onboarding::Status, onboarding_tracking_label: track_label) }

  subject { rendered }

  before do
    assign(:project, project)
    allow(view).to receive(:onboarding_status).and_return(onboarding_status)

    render
  end

  it { is_expected.to have_content("Ok, let's go") }
  it { is_expected.not_to have_content('Creating your onboarding experience...') }

  context 'with tracking' do
    where(:track_action) { %w[render click_ok_lets_go] }

    with_them do
      it 'contains render tracking' do
        css = "[data-track-action='#{track_action}']"
        css += "[data-track-label='#{track_label}']"

        expect(rendered).to have_css(css)
      end
    end
  end
end
