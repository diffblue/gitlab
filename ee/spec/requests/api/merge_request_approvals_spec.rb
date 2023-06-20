# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::MergeRequestApprovals, :aggregate_failures, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:admin) { create(:user, :admin) }
  let_it_be(:project, reload: true) { create(:project, :public, :repository, creator: user, namespace: user.namespace, only_allow_merge_if_pipeline_succeeds: false) }
  let_it_be(:approver) { create :user }
  let_it_be(:group) { create :group }

  let(:merge_request) { create(:merge_request, :simple, author: user, assignees: [user], source_project: project, target_project: project, title: "Test", created_at: Time.now) }

  shared_examples_for 'an API endpoint for getting merge request approval state' do
    context 'when source rule is present' do
      let(:source_rule) { create(:approval_project_rule, project: project, approvals_required: 1, name: 'zoo') }

      before do
        rule.create_approval_merge_request_rule_source!(approval_project_rule: source_rule)

        get api(url, user)
      end

      it 'returns source rule details' do
        expect(json_response['rules'].first['source_rule']['approvals_required']).to eq(source_rule.approvals_required)
      end
    end

    context 'when rule has groups' do
      before do
        rule.groups << group

        get api(url, user)
      end

      context 'when user can view a group' do
        let(:group) { create(:group) }

        it 'includes group' do
          rule = json_response['rules'].first

          expect(rule['groups'].size).to eq(1)
          expect(rule['groups']).to match([hash_including('id' => group.id)])
        end
      end

      context 'when user cannot view a group included in groups' do
        let(:group) { create(:group, :private) }

        it 'excludes private groups' do
          expect(json_response['rules'].first['groups'].size).to eq(0)
        end
      end
    end
  end

  describe 'GET :id/merge_requests/:merge_request_iid/approvals' do
    let!(:rule) { create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: 2, name: 'foo') }
    let(:path) { "/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals" }

    it 'retrieves the approval status' do
      project.add_developer(approver)
      project.add_developer(create(:user))
      merge_request.approvals.create!(user: approver)
      rule.users << approver
      rule.groups << group

      get api(path, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['approvals_required']).to eq 2
      expect(json_response['approvals_left']).to eq 1
      expect(json_response['approval_rules_left']).to be_empty
      expect(json_response['approved_by'][0]['user']['username']).to eq(approver.username)
      expect(json_response['user_can_approve']).to be false
      expect(json_response['user_has_approved']).to be false
      expect(json_response['approvers'][0]['user']['username']).to eq(approver.username)
      expect(json_response['approver_groups'][0]['group']['name']).to eq(group.name)
      expect(json_response['approved']).to be true
    end

    it 'lists unapproved rule names' do
      project.add_developer(approver)
      project.add_developer(create(:user))
      rule.users << approver
      rule.users << create(:user)
      rule.groups << group

      get api(path, approver)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['approvals_required']).to eq 2
      expect(json_response['approvals_left']).to eq 2

      short_approval = { "id" => rule.id, "name" => rule.name, "rule_type" => rule.rule_type.to_s }
      expect(json_response['approval_rules_left']).to eq([short_approval])

      expect(json_response['approved_by']).to be_empty
      expect(json_response['user_can_approve']).to be true
      expect(json_response['user_has_approved']).to be false
      expect(json_response['approvers'][0]['user']['username']).to eq(approver.username)
      expect(json_response['approver_groups'][0]['group']['name']).to eq(group.name)
      expect(json_response['approved']).to be false
    end

    context 'when private group approver' do
      before do
        private_group = create(:group, :private)
        private_group.add_developer(create(:user))
        merge_request.approver_groups.create!(group: private_group)
      end

      it 'hides private group' do
        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['approver_groups'].size).to eq(0)
      end

      context 'when admin' do
        it 'shows all approver groups' do
          get api(path, admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['approver_groups'].size).to eq(1)
        end
      end
    end

    context 'when approvers are set to zero' do
      before do
        create(:approval_project_rule, project: project, approvals_required: 0)
        get api(path, user)
      end

      it 'returns a 200' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['approved']).to be true
        expect(json_response['message']).to eq(nil)
      end
    end

    context 'when merge_status is cannot_be_merged_rechecking' do
      before do
        merge_request.update!(merge_status: 'cannot_be_merged_rechecking')
        get api(path, user)
      end

      it 'returns `checking`' do
        expect(json_response['merge_status']).to eq 'checking'
      end
    end
  end

  describe 'GET :id/merge_requests/:merge_request_iid/approval_settings' do
    let(:rule) { create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: 2, name: 'foo') }
    let(:url) { "/projects/#{project.id}/merge_requests/#{merge_request.iid}/approval_settings" }

    before do
      project.add_developer(approver)
      merge_request.approvals.create!(user: approver)
      rule.users << approver
    end

    it_behaves_like 'an API endpoint for getting merge request approval state'

    it 'retrieves the approval rules details' do
      get api(url, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['rules'].size).to eq(1)

      rule_response = json_response['rules'].first

      expect(rule_response['id']).to eq(rule.id)
      expect(rule_response['name']).to eq('foo')
      expect(rule_response['approvers'][0]['username']).to eq(approver.username)
      expect(rule_response['approved_by'][0]['username']).to eq(approver.username)
      expect(rule_response['commented_by']).to eq([])
      expect(rule_response['source_rule']).to be_nil
      expect(rule_response['section']).to be_nil
    end

    context "when rule has a section" do
      let(:rule) do
        create(
          :code_owner_rule,
          merge_request: merge_request,
          approvals_required: 2,
          name: "foo",
          section: "Example Section"
        )
      end

      it "exposes the value of section when set" do
        get api(url, user)

        rule_response = json_response["rules"].first

        expect(rule_response["section"]).to eq(rule.section)
      end
    end

    context 'when target_branch is specified' do
      let(:protected_branch) { create(:protected_branch, project: project, name: 'master') }
      let(:another_protected_branch) { create(:protected_branch, project: project, name: 'test') }

      let(:project_rule) do
        create(
          :approval_project_rule,
          project: project,
          protected_branches: [protected_branch]
        )
      end

      let(:another_project_rule) do
        create(
          :approval_project_rule,
          project: project,
          protected_branches: [another_protected_branch]
        )
      end

      let!(:another_rule) do
        create(
          :approval_merge_request_rule,
          approval_project_rule: another_project_rule,
          merge_request: merge_request
        )
      end

      before do
        rule.update!(approval_project_rule: project_rule)
      end

      it 'filters the rules returned by target branch' do
        get api("#{url}?target_branch=master", user)

        expect(json_response['rules'].size).to eq(1)

        rule_response = json_response['rules'].first

        expect(rule_response['id']).to eq(rule.id)
        expect(rule_response['name']).to eq('foo')
      end
    end
  end

  describe 'GET :id/merge_requests/:merge_request_iid/approval_state' do
    let(:rule) { create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: 2, name: 'foo') }
    let(:url) { "/projects/#{project.id}/merge_requests/#{merge_request.iid}/approval_state" }

    before do
      project.add_developer(approver)
      merge_request.approvals.create!(user: approver)
      rule.users << approver
    end

    it_behaves_like 'an API endpoint for getting merge request approval state'

    it 'retrieves the approval state details' do
      get api(url, user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['rules'].size).to eq(1)

      rule_response = json_response['rules'].first

      expect(rule_response['id']).to eq(rule.id)
      expect(rule_response['name']).to eq('foo')
      expect(rule_response['eligible_approvers'][0]['username']).to eq(approver.username)
      expect(rule_response['approved_by'][0]['username']).to eq(approver.username)
      expect(rule_response['source_rule']).to eq(nil)
    end
  end

  describe 'POST :id/merge_requests/:merge_request_iid/approvals' do
    let(:path) { "/projects/#{project.id}/merge_requests/#{merge_request.iid}/approvals" }
    let(:params) { { approvals_required: 5 } }
    let(:current_user) { user }

    it_behaves_like 'POST request permissions for admin mode'

    shared_examples_for 'cannot update approval rules' do
      context 'when users cannot update approval rules' do
        before do
          allow(Ability).to receive(:allowed?).and_call_original
          allow(Ability).to receive(:allowed?).with(current_user, :edit_approval_rule, anything).and_return(false)
        end

        it 'returns 403 error' do
          post api(path, current_user, admin_mode: true), params: params

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['message']).to eq ['Prohibited']
        end
      end
    end

    shared_examples_for 'user allowed to override approvals_before_merge' do
      context 'when approval rule is missing for the merge request' do
        it 'creates an approval rule with required number of approvals' do
          post api(path, current_user, admin_mode: true), params: params

          approval_rule = merge_request.approval_rules.any_approver.first
          expect(approval_rule.approvals_required).to eq(5)

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['approvals_required']).to eq(5)
        end

        it_behaves_like 'cannot update approval rules'
      end

      context 'when approval rules already exist for the merge request' do
        let!(:any_approver_rule) { create(:any_approver_rule, merge_request: merge_request, approvals_required: 1) }
        let!(:custom_rule) { create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: 2) }

        it 'updates any approval rule with required number of approvals' do
          expect do
            post api(path, current_user, admin_mode: true), params: params
          end.to change { any_approver_rule.reload.approvals_required }.from(1).to(5)
                   .and change { custom_rule.reload.approvals_required }.by(0)

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['approvals_required']).to eq(5)
        end

        it_behaves_like 'cannot update approval rules'
      end
    end

    context 'when disable_overriding_approvers_per_merge_request is true on the project' do
      before do
        project.update!(disable_overriding_approvers_per_merge_request: true)
      end

      it 'does not allow you to set approvals_before_merge' do
        expect do
          post api(path, current_user, admin_mode: true), params: params
        end.not_to change { merge_request.approval_rules.any_approver.reload.first }.from(nil)

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'as a project admin' do
      it_behaves_like 'user allowed to override approvals_before_merge' do
        let(:current_user) { user }
        let(:expected_approver_group_size) { 0 }
      end
    end

    context 'as a global admin' do
      it_behaves_like 'user allowed to override approvals_before_merge' do
        let(:current_user) { admin }
        let(:expected_approver_group_size) { 1 }
      end
    end

    context 'as a random user' do
      before do
        project.update!(disable_overriding_approvers_per_merge_request: false)
      end

      it 'does not allow you to override approvals required' do
        expect do
          post api(path, user2), params: params
        end.not_to change { merge_request.approval_rules.any_approver.reload.first }.from(nil)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'POST :id/merge_requests/:merge_request_iid/approve' do
    let!(:rule) { create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: 2) }

    context 'as the author of the merge request' do
      before do
        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approve", user)
      end

      it 'returns a 401' do
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'as a valid approver' do
      let_it_be(:approver) { create(:user) }

      before do
        project.add_developer(approver)
        project.add_developer(create(:user))
        rule.users << approver
      end

      def approve(extra_params = {})
        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/approve", approver), params: extra_params
      end

      context 'when the sha param is not set' do
        before do
          approve
        end

        it 'approves the merge request' do
          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['approvals_left']).to eq(1)
          expect(json_response['approved_by'][0]['user']['username']).to eq(approver.username)
          expect(json_response['user_has_approved']).to be true
          expect(json_response['approved']).to be true
        end
      end

      context 'when the sha param is correct' do
        before do
          approve(sha: merge_request.diff_head_sha)
        end

        it 'approves the merge request' do
          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['approvals_left']).to eq(1)
          expect(json_response['approved_by'][0]['user']['username']).to eq(approver.username)
          expect(json_response['user_has_approved']).to be true
          expect(json_response['approved']).to be true
        end
      end

      context 'when the sha param is incorrect' do
        before do
          approve(sha: merge_request.diff_head_sha.reverse)
        end

        it 'returns a 409' do
          expect(response).to have_gitlab_http_status(:conflict)
        end

        it 'does not approve the merge request' do
          expect(merge_request.reload.approval_state.approvals_left).to eq(2)
        end
      end

      context 'when project requires force auth for approval' do
        before do
          project.update!(require_password_to_approve: true)
        end

        it 'does not approve the merge request with no password' do
          approve

          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(merge_request.reload.approvals_left).to eq(2)
        end

        it 'does not approve the merge request with incorrect password' do
          approve(approval_password: 'incorrect')

          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(merge_request.reload.approvals_left).to eq(2)
        end

        it 'approves the merge request with correct password' do
          approve(approval_password: approver.password)

          expect(response).to have_gitlab_http_status(:created)
          expect(merge_request.reload.approvals_left).to eq(1)
        end
      end

      it 'only shows group approvers visible to the user' do
        private_group = create(:group, :private)
        merge_request.approver_groups.create!(group: private_group)

        approve

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['approver_groups'].size).to eq(0)
      end
    end
  end

  describe 'POST :id/merge_requests/:merge_request_iid/unapprove' do
    let!(:rule) { create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: 2, name: 'foo') }

    context 'as a user who has approved the merge request' do
      let_it_be(:approver) { create(:user) }
      let_it_be(:unapprover) { create(:user) }

      before do
        project.add_developer(approver)
        project.add_developer(unapprover)
        project.add_developer(create(:user))
        merge_request.approvals.create!(user: approver)
        merge_request.approvals.create!(user: unapprover)
        rule.users = [approver, unapprover]
      end

      it 'unapproves the merge request' do
        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/unapprove", unapprover)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['approvals_left']).to eq(1)
        usernames = json_response['approved_by'].map { |u| u['user']['username'] }
        expect(usernames).not_to include(unapprover.username)
        expect(usernames.size).to be 1
        expect(json_response['user_has_approved']).to be false
        expect(json_response['user_can_approve']).to be true
        expect(json_response['user_can_approve']).to be true
        expect(json_response['approved']).to be false
      end

      it 'only shows group approvers visible to the user' do
        private_group = create(:group, :private)
        merge_request.approver_groups.create!(group: private_group)

        post api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/unapprove", unapprover)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['approver_groups'].size).to eq(0)
      end
    end
  end
end
