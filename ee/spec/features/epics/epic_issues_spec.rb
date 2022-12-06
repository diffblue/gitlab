# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Epic Issues', :js, feature_category: :portfolio_management do
  include NestedEpicsHelper
  include DragTo

  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:epic) { create(:epic, group: group) }
  let(:public_project) { create(:project, :public, group: group) }
  let(:private_project) { create(:project, :private, group: group) }
  let(:public_issue) { create(:issue, project: public_project) }
  let(:private_issue) { create(:issue, project: private_project) }

  let!(:epic_issues) do
    [
      create(:epic_issue, epic: epic, issue: public_issue, relative_position: 1),
      create(:epic_issue, epic: epic, issue: private_issue, relative_position: 2)
    ]
  end

  let!(:nested_epics) do
    [
      create(:epic, group: group, parent_id: epic.id, relative_position: 1),
      create(:epic, group: group, parent_id: epic.id, relative_position: 2)
    ]
  end

  before do
    stub_licensed_features(epics: true, subepics: true)
  end

  def visit_epic
    sign_in(user)
    visit group_epic_path(group, epic)

    wait_for_requests

    find('.js-epic-tree-tab').click

    wait_for_requests
  end

  def visit_epic_no_subepic
    sign_in(user)
    visit group_epic_path(group, epic)

    wait_for_requests
  end

  context 'when user is not a group member of a public group' do
    before do
      visit_epic
    end

    it 'user can see issues from public project but cannot delete the associations' do
      within('.related-items-tree-container ul.related-items-list') do
        expect(page).to have_selector('li', count: 3)
        expect(page).to have_content(public_issue.title)
        expect(page).not_to have_selector('button.js-issue-item-remove-button')
      end
    end

    it 'user cannot add new issues to the epic' do
      expect(page).not_to have_selector('.related-items-tree-container .js-issue-actions-split-button > button:first-child')
    end
  end

  context 'when user is a group member' do
    let(:issue_to_add) { create(:issue, project: private_project) }
    let(:issue_invalid) { create(:issue) }
    let(:epic_to_add) { create(:epic, group: group) }

    def add_issues(references)
      find(".related-items-tree-container .js-add-epics-issues-button").click
      find('.related-items-tree-container .js-add-epics-issues-button .dropdown-item', text: 'Add an existing issue').click
      fill_in 'Paste issue link', with: "#{references} "
      within '.add-item-form-container' do
        click_button 'Add'
      end

      wait_for_requests
    end

    def add_epics(references)
      find('.related-items-tree-container .js-add-epics-issues-button').click
      find('.related-items-tree-container .js-add-epics-issues-button .dropdown-item', text: 'Add an existing epic').click
      fill_in 'Paste epic link', with: "#{references} "
      within '.add-item-form-container' do
        click_button 'Add'
      end

      wait_for_requests
    end

    before do
      group.add_developer(user)
      visit_epic
    end

    context 'handling epics' do
      it 'user can display create new epic form by clicking the dropdown item' do
        expect(page).not_to have_selector('input[placeholder="New epic title"]')

        find('.related-items-tree-container .js-add-epics-issues-button .dropdown-toggle').click
        find('.related-items-tree-container .js-add-epics-issues-button .dropdown-item', text: 'Add a new epic').click

        expect(page).to have_selector('input[placeholder="New epic title"]')
      end
    end

    context 'handling epic issues' do
      it 'user can see all issues of the group and delete the associations' do
        within('.related-items-tree-container ul.related-items-list') do
          expect(page).to have_selector('li.js-item-type-issue', count: 2)
          expect(page).to have_content(public_issue.title)
          expect(page).to have_content(private_issue.title)

          first('li.js-item-type-issue button.js-issue-item-remove-button').click
        end
        first('#item-remove-confirmation .modal-footer .btn-danger').click

        wait_for_requests

        within('.related-items-tree-container ul.related-items-list') do
          expect(page).to have_selector('li.js-item-type-issue', count: 1)
        end
      end

      it 'user cannot add new issues to the epic from another group' do
        add_issues(issue_invalid.to_reference(full: true))

        expect(page).to have_selector('.gl-field-error')
        expect(find('.gl-field-error')).to have_text("Issue cannot be found.")
      end

      it 'user can add new issues to the epic' do
        references = issue_to_add.to_reference(full: true)

        add_issues(references)

        expect(page).not_to have_selector('.gl-field-error')
        expect(page).not_to have_content("Issue cannot be found.")

        within('.related-items-tree-container ul.related-items-list') do
          expect(page).to have_selector('li.js-item-type-issue', count: 3)
        end
      end

      it 'user cannot add new issue that does not exist' do
        add_issues("&123")

        expect(page).to have_selector('.gl-field-error')
        expect(find('.gl-field-error')).to have_text("Issue cannot be found.")
      end
    end

    context 'handling epic links' do
      context 'when subepics feature is enabled' do
        it 'user can see all epics of the group and delete the associations' do
          within('.related-items-tree-container ul.related-items-list') do
            expect(page).to have_selector('li.js-item-type-epic', count: 2)
            expect(page).to have_content(nested_epics[0].title)
            expect(page).to have_content(nested_epics[1].title)

            first('li.js-item-type-epic button.js-issue-item-remove-button').click
          end
          first('#item-remove-confirmation .modal-footer .btn-danger').click

          wait_for_requests

          within('.related-items-tree-container ul.related-items-list') do
            expect(page).to have_selector('li.js-item-type-epic', count: 1)
          end
        end

        it 'user cannot add new epic that does not exist' do
          add_epics("&123")

          expect(page).to have_selector('.gl-field-error')
          expect(find('.gl-field-error')).to have_text("Epic cannot be found.")
        end

        it 'user can add new epics to the epic' do
          references = epic_to_add.to_reference(full: true)
          add_epics(references)

          expect(page).not_to have_selector('.gl-field-error')
          expect(page).not_to have_content("Epic cannot be found.")

          within('.related-items-tree-container ul.related-items-list') do
            expect(page).to have_selector('li.js-item-type-epic', count: 3)
          end
        end

        context 'when epics are nested too deep' do
          before do
            last_child = add_children_to(epic: epic, count: 6)
            visit group_epic_path(group, last_child)

            wait_for_requests
          end

          it 'user cannot add new epic when hierarchy level limit has been reached' do
            references = epic_to_add.to_reference(full: true)
            add_epics(references)

            expect(page).to have_selector('.gl-field-error')
            expect(find('.gl-field-error')).to have_text("This epic cannot be added. One or more epics would exceed the maximum depth (#{Epic::MAX_HIERARCHY_DEPTH}) from its most distant ancestor.")
          end
        end
      end

      context 'when subepics feature is disabled' do
        it 'user can not add new epics to the epic' do
          stub_licensed_features(epics: true, subepics: false)

          visit_epic_no_subepic
          find('.related-items-tree-container .js-add-epics-issues-button').click

          expect(page).not_to have_selector('.related-items-tree-container .js-add-epics-issues-button .dropdown-item', text: 'Add an existing epic')
          expect(page).not_to have_selector('.related-items-tree-container .js-add-epics-issues-button .dropdown-item', text: 'Add a new epic')
        end
      end
    end

    it 'user can add new issues to the epic' do
      references = issue_to_add.to_reference(full: true)

      add_issues(references)

      expect(page).not_to have_selector('.gl-field-error')
      expect(page).not_to have_content("Issue cannot be found.")

      within('.related-items-tree-container ul.related-items-list') do
        expect(page).to have_selector('li.js-item-type-issue', count: 3)
      end
    end

    it 'user does not see the linked issues part of the form when they click "Add an existing issue"' do
      find(".related-items-tree-container .js-add-epics-issues-button").click
      find('.related-items-tree-container .js-add-epics-issues-button .dropdown-item', text: 'Add an existing issue').click

      expect(page).not_to have_content("The current issue")
      expect(page).not_to have_content("is blocked by")
      expect(page).not_to have_content("the following issue(s)")
    end
  end
end
