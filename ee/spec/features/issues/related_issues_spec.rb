# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Related issues', :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:project_b) { create(:project_empty_repo, :public) }
  let_it_be(:project_unauthorized) { create(:project_empty_repo, :public) }
  let_it_be(:issue_a) { create(:issue, project: project) }
  let_it_be(:issue_b) { create(:issue, project: project) }
  let_it_be(:issue_c) { create(:issue, project: project) }
  let_it_be(:issue_d) { create(:issue, project: project) }
  let_it_be(:issue_project_b_a) { create(:issue, project: project_b) }
  let_it_be(:issue_project_unauthorized_a) { create(:issue, project: project_unauthorized) }

  shared_examples 'issue closed by modal' do |selector|
    it 'shows a modal to confirm closing the issue' do
      # Workaround for modal not showing when issue is first added
      visit project_issue_path(project, issue_a)

      wait_for_requests

      within(selector) do
        click_button 'Close issue'
      end

      within('.modal-content', visible: true) do
        expect(page).to have_text 'Are you sure you want to close this blocked issue?'
        expect(page).to have_link("##{issue_b.iid}", href: project_issue_path(project, issue_b))

        click_button 'Yes, close issue'
      end

      wait_for_requests

      expect(page).not_to have_selector('.modal-content', visible: true)

      within(first('.issuable-status-badge', visible: :all)) do
        expect(page).to have_text 'Closed'
      end
    end
  end

  context 'when user has permission to manage related issues' do
    before do
      project.add_maintainer(user)
      project_b.add_maintainer(user)
      sign_in(user)
    end

    context 'with "Relates to", "Blocks", "Is blocked by" groupings' do
      def add_linked_issue(issue, radio_input_value)
        click_button 'Add a related issue'
        fill_in 'Paste issue link', with: "#{issue.to_reference(project)} "
        find("input[name=\"linked-issue-type-radio\"][value=\"#{radio_input_value}\"]").click
        page.within('.linked-issues-card-body') do
          click_button 'Add'
        end

        wait_for_requests
      end

      before do
        visit project_issue_path(project, issue_a)
        wait_for_requests
      end

      context 'when adding a "relates_to" issue' do
        before do
          add_linked_issue(issue_b, "relates_to")
        end

        it 'shows "Relates to" heading' do
          headings = all('.linked-issues-card-body h4')

          expect(headings.count).to eq(1)
          expect(headings[0].text).to eq("Relates to")
        end

        it 'shows the added issue' do
          items = all('.item-title a')

          expect(items[0].text).to eq(issue_b.title)
          expect(find('.js-related-issues-header-issue-count')).to have_content('1')
        end
      end

      context 'when adding a "blocks" issue' do
        before do
          add_linked_issue(issue_b, "blocks")
        end

        it 'shows "Blocks" heading' do
          headings = all('.linked-issues-card-body h4')

          expect(headings.count).to eq(1)
          expect(headings[0].text).to eq("Blocks")
        end

        it 'shows the added issue' do
          items = all('.item-title a')

          expect(items[0].text).to eq(issue_b.title)
          expect(find('.js-related-issues-header-issue-count')).to have_content('1')
        end
      end

      context 'when adding an "is_blocked_by" issue' do
        before do
          add_linked_issue(issue_b, "is_blocked_by")
        end

        it 'shows "Is blocked by" heading' do
          headings = all('.linked-issues-card-body h4')

          expect(headings.count).to eq(1)
          expect(headings[0].text).to eq("Is blocked by")
        end

        it 'shows the added issue' do
          items = all('.item-title a')

          expect(items[0].text).to eq(issue_b.title)
          expect(find('.js-related-issues-header-issue-count')).to have_content('1')
        end

        context 'when clicking the top `Close issue` button in the issue header', :aggregate_failures do
          it_behaves_like 'issue closed by modal', '.detail-page-header'
        end

        context 'when clicking the bottom `Close issue` button below the comment textarea', :aggregate_failures do
          it_behaves_like 'issue closed by modal', '.new-note'
        end
      end

      context 'when adding "relates_to", "blocks", and "is_blocked_by" issues' do
        before do
          add_linked_issue(issue_b, "relates_to")
          add_linked_issue(issue_c, "blocks")
          add_linked_issue(issue_d, "is_blocked_by")
        end

        it 'shows "Blocks", "Is blocked by", and "Relates to" headings' do
          headings = all('.linked-issues-card-body h4')

          expect(headings.count).to eq(3)
          expect(headings[0].text).to eq("Blocks")
          expect(headings[1].text).to eq("Is blocked by")
          expect(headings[2].text).to eq("Relates to")
        end

        it 'shows all added issues' do
          items = all('.item-title a')

          expect(items.count).to eq(3)
          expect(find('.js-related-issues-header-issue-count')).to have_content('3')
        end
      end
    end
  end
end
