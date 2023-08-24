# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User approves via custom role', :js, feature_category: :code_review_workflow do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository, :in_group) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  before do
    stub_licensed_features(custom_roles: true)
    sign_in(current_user)
  end

  context 'when the user has `admin_merge_request` enabled at the project level' do
    let_it_be(:admin_merge_request_role) do
      create(:member_role, :guest, namespace: project.group, admin_merge_request: true)
    end

    let_it_be(:project_member) do
      create(:project_member, :guest, member_role: admin_merge_request_role, user: current_user, project: project)
    end

    it 'allows approving and revoking approval' do
      visit project_merge_request_path(project, merge_request)
      expect(page).to have_button('Approve', exact: true)

      click_approval_button('Approve')
      expect(page).to have_content('Approved by you')

      click_approval_button('Revoke approval')
      expect(page).to have_content('Approval is optional')
    end
  end

  context 'when the user does not have the `admin_merge_request` permission enabled' do
    let_it_be(:non_admin_merge_request_role) do
      create(:member_role, :guest, namespace: project.group, admin_merge_request: false)
    end

    let_it_be(:project_member) do
      create(:project_member, :guest, member_role: non_admin_merge_request_role, user: current_user, project: project)
    end

    it 'prevents approving' do
      visit project_merge_request_path(project, merge_request)

      expect(page).not_to have_button('Approve', exact: true)
    end
  end

  def click_approval_button(action)
    page.within('.mr-state-widget') do
      click_button(action)
    end

    wait_for_requests
  end
end
