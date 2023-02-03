# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Panel do
  let_it_be(:project) { create(:project) }

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

  context 'with learn gitlab menu' do
    it 'contains the menu' do
      expect(contains_menu?(Sidebars::Projects::Menus::LearnGitlabMenu)).to be(true)
    end
  end

  def contains_menu?(menu)
    panel.instance_variable_get(:@menus).any?(menu)
  end
end
