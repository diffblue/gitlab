# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Epic in issue sidebar', :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:epic1) { create(:epic, group: group, title: 'Epic Foo') }
  let_it_be(:epic2) { create(:epic, group: group, title: 'Epic Bar') }
  let_it_be(:epic3) { create(:epic, group: group, title: 'Epic Baz') }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:epic_issue) { create(:epic_issue, epic: epic1, issue: issue) }

  let_it_be(:subgroup) { create(:group, :public, parent: group) }
  let_it_be(:subproject) { create(:project, :public, group: subgroup) }
  let_it_be(:subepic) { create(:epic, group: subgroup, title: 'Subgroup epic') }
  let_it_be(:subissue) { create(:issue, project: subproject) }

  let_it_be(:sidebar_epic_selector) { '[data-testid="sidebar-epic"]' }

  shared_examples 'epic in issue sidebar' do
    before do
      group.add_owner(user)
      sign_in user
    end

    context 'projects within a group' do
      before do
        visit project_issue_path(project, issue)
        wait_for_all_requests
      end

      it 'shows epic in issue sidebar' do
        expect(page.find(sidebar_epic_selector)).to have_content(epic1.title)
      end

      it 'shows edit button in issue sidebar' do
        expect(page.find(sidebar_epic_selector)).to have_button('Edit')
      end

      it 'shows epics select dropdown' do
        page.within(sidebar_epic_selector) do
          click_edit

          aggregate_failures do
            expect(page).to have_selector('.gl-dropdown-contents .gl-dropdown-item', count: 4)
            expect(page).to have_content 'No epic'
            expect(page).to have_content epic1.title
            expect(page).to have_content epic2.title
            expect(page).to have_content epic3.title
          end
        end
      end

      it 'supports searching for an epic' do
        page.within(sidebar_epic_selector) do
          click_edit

          page.find('.gl-form-input').send_keys('Foo')

          wait_for_all_requests

          aggregate_failures do
            expect(page).to have_selector('.gl-dropdown-contents .gl-dropdown-item', count: 2)
            expect(page).to have_content 'No epic'
            expect(page).to have_content epic1.title
          end
        end
      end

      it 'select an epic from the dropdown' do
        page.within(sidebar_epic_selector) do
          click_edit

          find('.gl-dropdown-item', text: epic2.title).click

          wait_for_all_requests

          expect(page.find('[data-testid="select-epic"]')).to have_content(epic2.title)
        end
      end
    end

    context 'project within a subgroup' do
      before do
        visit project_issue_path(subproject, issue)
        wait_for_all_requests
      end

      it 'shows all epics belonging to the sub group and its parents' do
        page.within(sidebar_epic_selector) do
          click_edit

          aggregate_failures do
            expect(page).to have_selector('.gl-dropdown-contents .gl-dropdown-item', count: 5)
            expect(page).to have_content 'No epic'
            expect(page).to have_content epic1.title
            expect(page).to have_content epic2.title
            expect(page).to have_content epic3.title
            expect(page).to have_content subepic.title
          end
        end
      end
    end

    context 'personal projects' do
      it 'does not show epic in issue sidebar' do
        personal_project = create(:project, :public)
        other_issue = create(:issue, project: personal_project)

        visit project_issue_path(personal_project, other_issue)

        expect_no_epic
      end
    end
  end

  context 'when epics available' do
    before do
      stub_licensed_features(epics: true)

      sign_in(user)
    end

    it_behaves_like 'epic in issue sidebar'

    context 'with namespaced plans', :saas do
      before do
        stub_application_setting(check_namespace_plan: true)
      end

      context 'group has license' do
        before do
          create(:gitlab_subscription, :ultimate, namespace: group)
        end

        it_behaves_like 'epic in issue sidebar'
      end

      context 'group has no license' do
        it 'does not show epic for public projects and groups' do
          visit project_issue_path(project, issue)

          expect_no_epic
        end
      end
    end
  end

  context 'when epics unavailable' do
    before do
      stub_licensed_features(epics: false)
    end

    it 'does not show epic in issue sidebar' do
      visit project_issue_path(project, issue)

      expect_no_epic
    end
  end

  def expect_no_epic
    expect(page).not_to have_selector('.block.epic')
  end

  def click_edit
    click_button 'Edit'

    wait_for_all_requests
  end
end
