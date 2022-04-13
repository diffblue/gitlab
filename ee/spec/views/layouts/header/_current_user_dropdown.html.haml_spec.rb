# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/header/_current_user_dropdown' do
  let_it_be(:user) { create(:user) }

  describe 'Buy Pipeline Minutes link in user dropdown' do
    let(:need_minutes) { true }
    let(:show_notification_dot) { false }
    let(:show_subtext) { false }

    before do
      allow(view).to receive(:current_user).and_return(user)
      allow(view).to receive(:show_buy_pipeline_minutes?).and_return(need_minutes)
      allow(view).to receive(:show_pipeline_minutes_notification_dot?).and_return(show_notification_dot)
      allow(view).to receive(:show_buy_pipeline_with_subtext?).and_return(show_subtext)
      allow(view).to receive(:root_ancestor_namespace).and_return(user.namespace)

      render
    end

    subject { rendered }

    context 'when pipeline minutes need bought without notification dot' do
      it 'has "Buy Pipeline minutes" link with correct data properties', :aggregate_failures do
        expect(subject).to have_selector('[data-track-action="click_buy_ci_minutes"]')
        expect(subject).to have_selector("[data-track-label='#{user.namespace.actual_plan_name}']")
        expect(subject).to have_selector('[data-track-property="user_dropdown"]')
        expect(subject).to have_link('Buy Pipeline minutes')
        expect(subject).not_to have_content('One of your groups is running out')
      end
    end

    context 'when pipeline minutes need bought and there is a notification dot' do
      let(:show_notification_dot) { true }

      it 'has "Buy Pipeline minutes" link with correct text', :aggregate_failures do
        expect(subject).to have_link('Buy Pipeline minutes')
        expect(subject).to have_content('One of your groups is running out')
        expect(subject).to have_selector('.js-follow-link')
        expect(subject).to have_selector("[data-feature-id='#{::Ci::RunnersHelper::BUY_PIPELINE_MINUTES_NOTIFICATION_DOT}']")
        expect(subject).to have_selector("[data-dismiss-endpoint='#{callouts_path}']")
      end
    end

    context 'when pipeline minutes need bought and notification dot has been acknowledged' do
      let(:show_subtext) { true }

      it 'has "Buy Pipeline minutes" link with correct text', :aggregate_failures do
        expect(subject).to have_link('Buy Pipeline minutes')
        expect(subject).to have_content('One of your groups is running out')
        expect(subject).not_to have_selector('.js-follow-link')
        expect(subject).not_to have_selector("[data-feature-id='#{::Ci::RunnersHelper::BUY_PIPELINE_MINUTES_NOTIFICATION_DOT}']")
        expect(subject).not_to have_selector("[data-dismiss-endpoint='#{callouts_path}']")
      end
    end

    context 'when ci minutes do not need bought' do
      let(:need_minutes) { false }

      it 'has no "Buy Pipeline minutes" link' do
        expect(subject).not_to have_link('Buy Pipeline minutes')
      end
    end
  end
end
