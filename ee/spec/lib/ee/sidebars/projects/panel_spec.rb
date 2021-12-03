# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Panel do
  let(:project) { build(:project) }
  let(:context) { Sidebars::Projects::Context.new(current_user: nil, container: project) }

  subject(:panel) { described_class.new(context) }

  describe 'ExternalIssueTrackerMenu' do
    before do
      allow_next_instance_of(Sidebars::Projects::Menus::IssuesMenu) do |issues_menu|
        allow(issues_menu).to receive(:show_jira_menu_items?).and_return(show_jira_menu_items)
      end
    end

    context 'when show_jira_menu_items? is false' do
      let(:show_jira_menu_items) { false }

      it 'contains ExternalIssueTracker menu' do
        expect(contains_external_issue_tracker_menu?).to be(true)
      end
    end

    context 'when show_jira_menu_items? is true' do
      let(:show_jira_menu_items) { true }

      it 'does not contain ExternalIssueTracker menu' do
        expect(contains_external_issue_tracker_menu?).to be(false)
      end
    end

    def contains_external_issue_tracker_menu?
      contains_menu?(Sidebars::Projects::Menus::ExternalIssueTrackerMenu)
    end
  end

  describe 'BillingMenu' do
    context 'with candidate experience' do
      before do
        stub_experiments(billing_in_side_nav: :candidate)
      end

      it 'assigns the candidate experience and tracks the event' do
        expect(contains_billing_menu?).to be(true)
      end
    end

    context 'with control experience' do
      before do
        stub_experiments(billing_in_side_nav: :control)
      end

      it 'assigns the candidate experience and tracks the event' do
        expect(contains_billing_menu?).to be(false)
      end
    end

    def contains_billing_menu?
      contains_menu?(Sidebars::Projects::Menus::BillingMenu)
    end
  end

  def contains_menu?(menu)
    panel.instance_variable_get(:@menus).any? { |i| i.is_a?(menu) }
  end
end
