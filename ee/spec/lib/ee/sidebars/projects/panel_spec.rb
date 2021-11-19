# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Panel do
  let(:project) { build(:project) }
  let(:context) { Sidebars::Projects::Context.new(current_user: nil, container: project) }

  describe 'ExternalIssueTrackerMenu' do
    before do
      allow_next_instance_of(Sidebars::Projects::Menus::IssuesMenu) do |issues_menu|
        allow(issues_menu).to receive(:show_jira_menu_items?).and_return(show_jira_menu_items)
      end
    end

    subject { described_class.new(context) }

    def contains_external_issue_tracker_menu
      subject.instance_variable_get(:@menus).any? { |i| i.is_a?(Sidebars::Projects::Menus::ExternalIssueTrackerMenu) }
    end

    context 'when show_jira_menu_items? is false' do
      let(:show_jira_menu_items) { false }

      it 'contains ExternalIssueTracker menu' do
        expect(contains_external_issue_tracker_menu).to be(true)
      end
    end

    context 'when show_jira_menu_items? is true' do
      let(:show_jira_menu_items) { true }

      it 'does not contain ExternalIssueTracker menu' do
        expect(contains_external_issue_tracker_menu).to be(false)
      end
    end
  end
end
