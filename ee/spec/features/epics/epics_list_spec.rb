# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'epics list', :js, feature_category: :portfolio_management do
  include FilteredSearchHelpers

  let(:group) { create(:group, :public, name: 'group') }
  let(:user) { create(:user) }
  let(:user_dev) { create(:user) }
  let!(:bug_label) { create(:group_label, group: group, title: 'Bug') }
  let!(:docs_label) { create(:group_label, group: group, title: 'Documentation') }
  let!(:enhancement_label) { create(:group_label, group: group, title: 'Enhancement') }
  let!(:critical_label) { create(:group_label, group: group, title: 'Critical') }

  before do
    stub_licensed_features(epics: true)

    sign_in(user)
  end

  context 'epics list' do
    available_tokens = %w[Author Label My-Reaction]
    available_sort_options = ['Created date', 'Updated date', 'Start date', 'Due date', 'Title']

    describe 'within a group' do
      let!(:epic1) { create(:epic, group: group, start_date: '2020-12-15', end_date: '2021-1-15', labels: [docs_label]) }
      let!(:epic2) { create(:epic, group: group, start_date: '2020-12-15', labels: [docs_label, enhancement_label]) }
      let!(:epic3) { create(:epic, group: group, end_date: '2021-1-15', labels: [enhancement_label]) }
      let!(:blocked_epic) { create(:epic, group: group, end_date: '2022-1-15') }
      let!(:epic_link) { create(:related_epic_link, source: epic2, target: blocked_epic, link_type: IssuableLink::TYPE_BLOCKS) }
      let!(:award_emoji_star) { create(:award_emoji, name: 'star', user: user, awardable: epic1) }
      let!(:award_emoji_upvote) { create(:award_emoji, :upvote, user: user, awardable: epic1) }
      let!(:award_emoji_downvote) { create(:award_emoji, :downvote, user: user, awardable: epic2) }

      shared_examples 'epic list' do
        it 'renders epics list', :aggregate_failures do
          page.within('.issuable-list-container') do
            expect(page).to have_selector('.gl-tabs')
            expect(page).to have_selector('.vue-filtered-search-bar-container')
            expect(page.find('.issuable-list')).to have_selector('li.issue', count: 4)
          end
        end

        it 'renders epics item with metadata', :aggregate_failures do
          page.within(".issuable-list #issuable_#{epic2.id}.issue") do
            expect(page).to have_link(epic2.title)
            expect(page).to have_text("&#{epic2.iid}")
            expect(page).to have_selector('.issuable-meta [data-testid="issuable-downvotes"]')
            expect(page.find('.issuable-meta [data-testid="issuable-blocking-count"]')).to have_content('1')
            expect(page).to have_text("created just now by #{epic2.author.name}")
          end

          page.within(".issuable-list #issuable_#{epic1.id}.issue") do
            expect(page).to have_selector('.issuable-meta [data-testid="issuable-upvotes"]')
          end
        end

        it 'renders epic item timeframe', :aggregate_failures do
          issues = page.all('.issue')

          expect(issues[0]).to have_text('Dec 15, 2020 – No due date')
          expect(issues[1]).to have_text('Dec 15, 2020 – Jan 15, 2021')
          expect(issues[3]).to have_text('No start date – Jan 15, 2021')
        end
      end

      context 'when signed in' do
        before do
          group.add_developer(user)
          group.add_developer(user_dev)
          visit group_epics_path(group)
          wait_for_requests
        end

        it 'renders epics list header actions', :aggregate_failures do
          page.within('.issuable-list-container .nav-controls') do
            expect(page).to have_button('Bulk edit')
            expect(page).to have_link('New epic')
          end
        end

        it_behaves_like 'epic list'

        it_behaves_like 'filtered search bar', available_tokens, available_sort_options

        it 'filters epics list based on labels with "=" operator' do
          select_tokens 'Label', '=', docs_label.title, submit: true

          wait_for_requests

          page.within('.issuable-list-container') do
            expect(page.find('.issuable-list')).to have_selector('li.issue', count: 2)
          end
        end

        it 'filters epics list based on labels with "!=" operator', :aggregate_failures do
          select_tokens 'Label', '=', docs_label.title
          select_tokens 'Label', '!=', enhancement_label.title, submit: true

          wait_for_requests

          page.within('.issuable-list-container .issuable-list') do
            expect(page).to have_selector('li.issue', count: 1)
            expect(page.find('li.issue .issuable-info')).not_to have_selector('.gl-label', text: enhancement_label.title)
          end
        end

        it 'filters epics list based on labels with "||" operator', :aggregate_failures do
          select_tokens 'Label', '||', docs_label.title
          select_tokens 'Label', '||', enhancement_label.title, submit: true

          wait_for_requests

          page.within('.issuable-list-container .issuable-list') do
            expect(page).to have_selector('li.issue', count: 3)
          end
        end

        context 'with subgroup epics' do
          let(:subgroup) { create(:group, :public, parent: group, name: 'subgroup') }
          let!(:subgroup_epic) { create(:epic, group: subgroup) }
          let!(:subgroup_epic2) { create(:epic, group: subgroup) }

          before do
            visit group_epics_path(group)
            wait_for_requests
          end

          it 'filters by group', :aggregate_failures do
            expect(page).to have_selector('li.issue', count: 6)

            select_tokens 'Group', group.name, submit: true

            expect(page).to have_selector('li.issue', count: 4)

            click_button 'Clear'

            select_tokens 'Group', subgroup.name, submit: true

            expect(page).to have_selector('li.issue', count: 2)
          end
        end

        it 'shows bulk editing sidebar with actions and labels select dropdown', :aggregate_failures do
          click_button 'Bulk edit'

          page.within('.issuable-list-container aside.right-sidebar') do
            expect(page).to have_button('Update all', disabled: true)
            expect(page).to have_button('Cancel')

            expect(page).to have_selector('form#epics-list-bulk-edit')
            expect(page).to have_button('Label')
          end
        end

        it 'shows checkboxes for selecting epics while bulk editing sidebar is visible', :aggregate_failures do
          click_button 'Bulk edit'

          page.within('.issuable-list-container') do
            expect(page).to have_selector('.vue-filtered-search-bar-container input[type="checkbox"]')
            expect(page.first('.issuable-list li.issue')).to have_selector('.gl-form-checkbox input[type="checkbox"]')
          end
        end

        it 'applies label to multiple epics from bulk editing sidebar', :aggregate_failures do
          # Vertify that label `Bug` is not applied already
          expect(find('.issuable-list li.issue .issuable-info', match: :first)).not_to have_selector('.gl-label', text: bug_label.title)

          # Bulk edit all epics to apply label
          page.within('.issuable-list-container') do
            click_button 'Bulk edit'

            page.within('.vue-filtered-search-bar-container') do
              page.find('input[type="checkbox"]').click
            end

            page.within('aside.right-sidebar') do
              find('button.js-dropdown-button').click

              wait_for_requests

              click_link bug_label.title
              click_button 'Update all'

              wait_for_requests
            end
          end

          # Verify that label is applied
          expect(find('.issuable-list li.issue .issuable-info', match: :first)).to have_selector('.gl-label', text: bug_label.title)
        end
      end

      context 'when signed out' do
        before do
          sign_out user
          visit group_epics_path(group)
          wait_for_requests
        end

        it_behaves_like 'epic list'
      end
    end

    describe 'within a sub-group group' do
      let!(:subgroup) { create(:group, parent: group, name: 'subgroup') }
      let!(:sub_epic1) { create(:epic, group: subgroup, start_date: '2020-12-15', end_date: '2021-1-15') }
      let!(:sub_epic2) { create(:epic, group: subgroup, start_date: '2020-12-15') }
      let!(:award_emoji_star) { create(:award_emoji, name: 'star', user: user, awardable: sub_epic1) }

      before do
        subgroup.add_developer(user)
        subgroup.add_developer(user_dev)
        visit group_epics_path(subgroup)
        wait_for_requests
      end

      it_behaves_like 'filtered search bar', available_tokens, available_sort_options
    end
  end
end
