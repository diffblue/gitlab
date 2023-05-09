# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sets approvers', :js, feature_category: :code_review_workflow do
  include ProjectForksHelper
  include FeatureApprovalHelper
  include ListboxHelpers
  include CookieHelper

  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:config_selector) { '.js-approval-rules' }
  let(:modal_selector) { '#mr-edit-approvals-create-modal' }

  before do
    stub_licensed_features(admin_merge_request_approvers_rules: true)
  end

  context 'when editing an MR with a different author' do
    let(:author) { create(:user) }
    let(:merge_request) { create(:merge_request, author: author, source_project: project) }

    before do
      project.add_developer(user)
      project.add_developer(author)

      sign_in(user)
      visit edit_project_merge_request_path(project, merge_request)
    end

    it 'does not allow setting the author as an approver but allows setting the current user as an approver' do
      open_modal(text: 'Add approval rule')
      click_button 'Search users or groups'

      expect_no_listbox_item(author.name)
      expect_listbox_item(user.name)
    end
  end

  context 'when creating an MR from a fork' do
    let(:other_user) { create(:user) }
    let(:non_member) { create(:user) }
    let(:forked_project) { fork_project(project, user, repository: true) }

    before do
      project.add_developer(user)
      project.add_developer(other_user)

      sign_in(user)
      visit project_new_merge_request_path(forked_project, merge_request: { target_branch: 'master', source_branch: 'feature' })
    end

    it 'allows setting other users as approvers but does not allow setting the current user as an approver, and filters non members from approvers list', :sidekiq_might_not_need_inline do
      open_modal(text: 'Add approval rule')
      click_button 'Search users or groups'

      expect_listbox_item(other_user.name)
      expect_no_listbox_item(non_member.name)
    end
  end

  context "Group approvers" do
    let_it_be(:project) { create(:project, :public, :repository) }
    let_it_be(:group) { create(:group) }

    context 'when creating an MR' do
      let(:other_user) { create(:user) }

      before do
        project.add_developer(user)
        project.add_developer(other_user)
        group.add_developer(other_user)

        sign_in(user)
      end

      it 'allows setting groups as approvers', :sidekiq_inline do
        visit project_new_merge_request_path(project, merge_request: { target_branch: 'master', source_branch: 'feature' })

        open_modal(text: 'Add approval rule')
        click_button 'Search users or groups'

        expect_no_listbox_item(group.name)

        group.add_developer(user) # only display groups that user has access to

        visit project_new_merge_request_path(project, merge_request: { target_branch: 'master', source_branch: 'feature' })
        open_modal(text: 'Add approval rule')
        click_button 'Search users or groups'

        expect_listbox_item(group.name)

        select_listbox_item(group.name)

        within('.modal-content') do
          click_button 'Add approval rule'
        end

        click_on("Create merge request")
        wait_for_all_requests

        expect(page).to have_content("Requires 1 approval from eligible users.")
      end

      it 'allows delete approvers group when it is set in project', :sidekiq_inline do
        approver = create :user
        project.add_developer(approver)
        group.add_developer(approver)
        create :approval_project_rule, project: project, users: [approver], groups: [group], approvals_required: 1

        visit project_new_merge_request_path(project, merge_request: { target_branch: 'master', source_branch: 'feature' })

        open_modal
        remove_approver(group.name)

        within(modal_selector) do
          expect(page).to have_css('.content-list li', count: 1)
        end

        click_button 'Update approval rule'
        click_on("Create merge request")
        wait_for_all_requests
        find('[data-testid="widget-toggle"]').click
        wait_for_requests

        expect(page).to have_selector(".js-approvers img[alt='#{approver.name}']")
      end
    end

    context 'when editing an MR with a different author' do
      let(:other_user) { create(:user) }
      let(:merge_request) { create(:merge_request, source_project: project) }

      before do
        project.add_developer(user)

        sign_in(user)
        set_cookie('new-actions-popover-viewed', 'true')
      end

      it 'allows setting groups as approvers when there is possible group approvers' do
        group = create :group
        group_project = create(:project, :public, :repository, namespace: group)
        group_project_merge_request = create(:merge_request, source_project: group_project)
        group.add_developer(user)
        group.add_developer(other_user)

        visit edit_project_merge_request_path(group_project, group_project_merge_request)

        open_modal(text: 'Add approval rule')
        click_button 'Search users or groups'

        expect_listbox_item(group.name)

        select_listbox_item(group.name)
        within('.modal-content') do
          click_button 'Add approval rule'
        end

        click_on("Save changes")
        wait_for_all_requests

        expect(page).to have_content("Requires 1 approval from eligible users.")
      end

      it 'allows delete approvers group when it`s set in project' do
        approver = create :user
        project.add_developer(approver)
        group = create :group
        group.add_developer(other_user)
        group.add_developer(approver)
        create :approval_project_rule, project: project, users: [approver], groups: [group], approvals_required: 1

        visit edit_project_merge_request_path(project, merge_request)

        open_modal
        remove_approver(group.name)

        wait_for_requests
        within(modal_selector) do
          expect(page).to have_css('.content-list li', count: 1)
        end

        click_button 'Update approval rule'
        click_on("Save changes")
        wait_for_all_requests

        find('[data-testid="widget-toggle"]').click
        wait_for_requests

        expect(page).not_to have_selector(".js-approvers img[alt='#{other_user.name}']")
        expect(page).to have_selector(".js-approvers img[alt='#{approver.name}']")
        expect(page).to have_content("Requires 1 approval from eligible users.")
      end

      it 'allows changing approvals number' do
        approvers = create_list(:user, 3)
        approvers.each { |approver| project.add_developer(approver) }
        create :approval_project_rule, project: project, users: approvers, approvals_required: 2

        visit project_merge_request_path(project, merge_request)
        wait_for_requests

        # project setting in the beginning on the show MR page
        expect(page).to have_content("Requires 2 approvals from eligible users")

        find('.detail-page-header-actions').click_on 'Edit'
        open_modal

        expect(page).to have_field 'Approvals required', with: '2'

        fill_in 'Approvals required', with: '3'

        click_button 'Update approval rule'
        click_on('Save changes')
        wait_for_all_requests

        # new MR setting on the show MR page
        expect(page).to have_content("Requires 3 approvals from eligible users")

        # new MR setting on the edit MR page
        find('.detail-page-header-actions').click_on 'Edit'
        wait_for_requests

        open_modal

        expect(page).to have_field 'Approvals required', with: '3'
      end
    end
  end
end
