# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Project settings > [EE] Merge Request Approvals', :js, feature_category: :code_review_workflow do
  include GitlabRoutingHelper
  include FeatureApprovalHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:group_member) { create(:user) }
  let_it_be(:non_member) { create(:user) }
  let_it_be(:config_selector) { '.js-approval-rules' }
  let_it_be(:modal_selector) { '#project-settings-approvals-create-modal' }

  before do
    sign_in(user)
    project.add_maintainer(user)
    group.add_developer(user)
    group.add_developer(group_member)
  end

  it 'adds approver' do
    visit project_settings_merge_requests_path(project)

    open_modal(text: 'Add approval rule', expand: false)
    open_approver_select

    expect(find('.select2-results')).to have_content(user.name)
    expect(find('.select2-results')).not_to have_content(non_member.name)

    find('.user-result', text: user.name).click
    close_approver_select

    expect(find('.content-list')).to have_content(user.name)

    open_approver_select

    expect(find('.select2-results')).not_to have_content(user.name)

    close_approver_select
    within('.modal-content') do
      click_button 'Add approval rule'
    end
    wait_for_requests

    expect_avatar(find('.js-members'), user)
  end

  it 'adds approver group' do
    visit project_settings_merge_requests_path(project)

    open_modal(text: 'Add approval rule', expand: false)
    open_approver_select

    expect(find('.select2-results')).to have_content(group.name)

    find('.user-result', text: group.name).click
    close_approver_select

    expect(find('.content-list')).to have_content(group.name)

    within('.modal-content') do
      click_button 'Add approval rule'
    end
    wait_for_requests

    expect_avatar(find('.js-members'), group.users)
  end

  context 'with an approver group' do
    let_it_be(:non_group_approver) { create(:user) }
    let_it_be(:rule) { create(:approval_project_rule, project: project, groups: [group], users: [non_group_approver]) }

    before do
      project.add_developer(non_group_approver)
    end

    it 'removes approver group' do
      visit project_settings_merge_requests_path(project)

      expect_avatar(find('.js-members'), rule.approvers)

      open_modal(text: 'Edit', expand: false)
      remove_approver(group.name)
      click_button "Update approval rule"
      wait_for_requests

      expect_avatar(find('.js-members'), [non_group_approver])
    end
  end
end
