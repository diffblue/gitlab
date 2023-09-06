# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User approves via custom role', :js, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, :in_group) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:role) { create(:member_role, :guest, namespace: project.group) }
  let_it_be(:membership) { create(:project_member, :guest, member_role: role, user: user, project: project) }

  before do
    stub_licensed_features(custom_roles: true)
    sign_in(user)
  end

  shared_examples_for '`admin_merge_request` custom role' do |project_visibility:|
    before do
      project.update!(visibility: project_visibility)
      role.update!(admin_merge_request: has_admin_merge_request_role?)
    end

    context 'when the user has `admin_merge_request` enabled at the project level' do
      let(:has_admin_merge_request_role?) { true }

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
      let(:has_admin_merge_request_role?) { false }

      it 'prevents approving' do
        visit project_merge_request_path(project, merge_request)

        expect(page).not_to have_button('Approve', exact: true)
      end
    end
  end

  context 'with a public project' do
    it_behaves_like '`admin_merge_request` custom role', project_visibility: Gitlab::VisibilityLevel::PUBLIC
  end

  context 'with a private project' do
    it_behaves_like '`admin_merge_request` custom role', project_visibility: Gitlab::VisibilityLevel::PRIVATE
  end

  def click_approval_button(action)
    page.within('.mr-state-widget') do
      click_button(action)
    end

    wait_for_requests
  end
end
