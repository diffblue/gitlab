# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Filter issues by iteration', :js do
  include FilteredSearchHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }

  let_it_be(:iteration_1) { create(:iteration, group: group, start_date: Date.today) }
  let_it_be(:iteration_2) { create(:iteration, group: group) }

  let_it_be(:iteration_1_issue) { create(:issue, project: project, iteration: iteration_1) }
  let_it_be(:iteration_2_issue) { create(:issue, project: project, iteration: iteration_2) }
  let_it_be(:no_iteration_issue) { create(:issue, project: project) }

  shared_examples 'filters by iteration' do
    context 'when iterations are not available' do
      before do
        stub_licensed_features(iterations: false)

        visit page_path
      end

      it 'does not show the iteration filter option' do
        find('.filtered-search').set('iter')

        expect(find('#js-dropdown-hint')).not_to have_selector('.filter-dropdown .filter-dropdown-item', text: 'Iteration')
      end
    end

    context 'when iterations are available' do
      before do
        stub_licensed_features(iterations: true)

        visit page_path

        page.has_content?(iteration_1_issue.title)
        page.has_content?(iteration_2_issue.title)
        page.has_content?(no_iteration_issue.title)
      end

      shared_examples 'filters issues by iteration' do
        it 'filters correct issues' do
          aggregate_failures do
            expect(page).to have_content(iteration_1_issue.title)
            expect(page).not_to have_content(iteration_2_issue.title)
            expect(page).not_to have_content(no_iteration_issue.title)
          end
        end
      end

      shared_examples 'filters issues by negated iteration' do
        it 'filters by negated iteration' do
          aggregate_failures do
            expect(page).not_to have_content(iteration_1_issue.title)
            expect(page).to have_content(iteration_2_issue.title)
            expect(page).to have_content(no_iteration_issue.title)
          end
        end
      end

      context 'when passing specific iteration by title' do
        before do
          input_filtered_search("iteration:=\"#{iteration_1.title}\"")
        end

        it_behaves_like 'filters issues by iteration'
      end

      context 'when passing Current iteration' do
        before do
          input_filtered_search("iteration:=Current", extra_space: false)
        end

        it_behaves_like 'filters issues by iteration'
      end

      context 'when filtering by negated iteration' do
        before do
          visit page_path

          page.within('.filtered-search-wrapper') do
            find('.filtered-search').set('iter')
            click_button('Iteration')

            find('.btn-helptext', text: 'is not').click
            click_button(iteration_title)

            find('.filtered-search').send_keys(:enter)
          end
        end

        context 'with specific iteration' do
          let(:iteration_title) { iteration_1.title }

          it_behaves_like 'filters issues by negated iteration'
        end

        context 'with current iteration' do
          let(:iteration_title) { 'Current' }

          it_behaves_like 'filters issues by negated iteration'
        end
      end
    end
  end

  context 'project issues list' do
    let(:page_path) { project_issues_path(project) }
    let(:issue_title_selector) { '.issue .title' }

    it_behaves_like 'filters by iteration'

    context 'when vue_issuables_list is disabled' do
      before do
        stub_feature_flags(vue_issuables_list: false)
      end

      it_behaves_like 'filters by iteration'
    end
  end

  context 'group issues list' do
    let(:page_path) { issues_group_path(group) }
    let(:issue_title_selector) { '.issue .title' }

    it_behaves_like 'filters by iteration'

    context 'when vue_issuables_list is disabled' do
      before do
        stub_feature_flags(vue_issuables_list: false)
      end

      it_behaves_like 'filters by iteration'
    end
  end

  context 'project board' do
    let_it_be(:board) { create(:board, project: project) }
    let_it_be(:backlog_list) { create(:backlog_list, board: board) }

    let(:page_path) { project_board_path(project, board) }
    let(:issue_title_selector) { '.board-card .board-card-title' }

    it_behaves_like 'filters by iteration'
  end

  context 'group board' do
    let_it_be(:board) { create(:board, group: group) }
    let_it_be(:backlog_list) { create(:backlog_list, board: board) }
    let_it_be(:user) { create(:user) }

    let(:page_path) { group_board_path(group, board) }
    let(:issue_title_selector) { '.board-card .board-card-title' }

    before_all do
      group.add_developer(user)
    end

    before do
      sign_in user
    end

    it_behaves_like 'filters by iteration'
  end
end
