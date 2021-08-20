# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'trial_registrations/new.html.haml' do
  let_it_be(:resource) { Users::AuthorizedBuildService.new(nil, {}).execute }

  before do
    allow(view).to receive(:resource).and_return(resource)
    allow(view).to receive(:resource_name).and_return(:user)
  end

  subject { render && rendered }

  describe 'trial_registration_with_reassurance experiment', :experiment do
    context 'when the experiment is enabled' do
      let(:variant) { :control }

      before do
        stub_experiments(trial_registration_with_reassurance: variant)
      end

      context 'when in the control' do
        it { is_expected.to have_content('Start a Free Ultimate Trial') }
        it { is_expected.not_to have_content('Free 30-day trial') }
        it { is_expected.not_to have_content('No credit card required.') }
        it { is_expected.not_to have_selector('img[alt$=" logo"]') }
      end

      context 'when in the candidate' do
        let(:variant) { :candidate }

        it { is_expected.not_to have_content('Start a Free Ultimate Trial') }
        it { is_expected.to have_content('Free 30-day trial') }
        it { is_expected.to have_content('No credit card required.') }
        it { is_expected.to have_selector('img[alt$=" logo"]') }
      end
    end

    describe 'tracking page-render using a frontend event' do
      context 'when the experiment should be tracked, like when it is enabled' do
        before do
          stub_experiments(trial_registration_with_reassurance: :control)
        end

        it { is_expected.to have_selector('span[data-track-action="render"]') }
      end

      context 'when the experiment should not be tracked, like when it is disabled' do
        before do
          stub_feature_flags(trial_registration_with_reassurance: false)
        end

        it { is_expected.not_to have_selector('span[data-track-action="render"]') }
      end
    end
  end
end
