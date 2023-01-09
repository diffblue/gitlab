# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'user sees MR approvals promo', :js, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:promo_title) { s_("ApprovalRule|Improve your organization's code review with required approvals.") }

  before do
    group.add_owner(user)

    stub_application_setting(check_namespace_plan: true)
    stub_licensed_features(merge_request_approvers: false)

    sign_in(user)
  end

  describe 'when creating an MR' do
    before do
      visit project_new_merge_request_path(project,
        merge_request: { source_branch: 'fix', target_branch: 'master' }
      )
    end

    it 'shows the promo text' do
      expect(page).to have_text(promo_title)
    end
  end

  describe 'when editing an MR' do
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }

    before do
      visit edit_project_merge_request_path(project, merge_request)
    end

    it 'shows the promo text' do
      expect(page).to have_text(promo_title)
    end
  end
end
