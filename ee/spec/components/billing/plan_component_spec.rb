# frozen_string_literal: true
require "spec_helper"

RSpec.describe Billing::PlanComponent, :aggregate_failures, type: :component, feature_category: :purchase do
  include SubscriptionPortalHelpers

  let(:namespace) { build(:group) }
  let(:plans_data) { billing_plans_data.map { |plan| Hashie::Mash.new(plan) } }
  let(:plan) { plans_data.detect { |x| x.code == plan_name } }

  subject(:component) { described_class.new(plan: plan, namespace: namespace) }

  before do
    allow(component).to receive(:plan_purchase_url).and_return('_purchase_url_')

    render_inline(component)
  end

  shared_examples 'plan tracking' do
    it 'has expected tracking attributes' do
      css = "[data-track-action='click_button'][data-track-label='plan_cta'][data-track-property='#{plan_name}']"

      expect(page).to have_css(css)
    end
  end

  context 'with free plan' do
    let(:plan_name) { 'free' }

    it 'has header for the current plan' do
      expect(page).to have_content('Your current plan')
      expect(page).to have_selector('.gl-bg-gray-100')
    end

    it 'has pricing info' do
      expect(page).to have_content('$0')
      expect(page).not_to have_content('Billed annually')
    end

    it 'does not have cta_link' do
      expect(page).not_to have_link('Learn more')
    end
  end

  context 'with premium plan' do
    let(:plan_name) { 'premium' }

    it 'has header for the current plan' do
      expect(page).to have_content('Recommended')
      expect(page).to have_selector('.gl-bg-purple-800')
    end

    it 'has pricing info' do
      expect(page).not_to have_content('$0')
      expect(page).to have_content('Billed annually')
    end

    it 'has expected cta_link' do
      expect(page).to have_link('Upgrade to Premium', href: '_purchase_url_')
    end

    it 'adds qa selector to cta link' do
      css = "[data-track-label='plan_cta'][data-qa-selector='upgrade_to_#{plan_name}']" # rubocop:disable QA/SelectorUsage

      expect(page).to have_css(css)
    end

    it_behaves_like 'plan tracking'
  end

  context 'with ultimate plan' do
    let(:plan_name) { 'ultimate' }

    it 'has header for the current plan' do
      expect(page).to have_selector('.gl-bg-gray-100')
    end

    it 'has pricing info' do
      expect(page).not_to have_content('$0')
      expect(page).to have_content('Billed annually')
    end

    it 'has expected cta_link' do
      expect(page).to have_link('Upgrade to Ultimate', href: '_purchase_url_')
    end

    it 'adds qa selector to cta link' do
      css = "[data-track-label='plan_cta'][data-qa-selector='upgrade_to_#{plan_name}']" # rubocop:disable QA/SelectorUsage

      expect(page).to have_css(css)
    end

    it_behaves_like 'plan tracking'
  end

  context 'with unsupported plan' do
    let(:plan_name) { 'bronze' }

    it 'does not render' do
      expect(page).to have_content('')
    end
  end
end
