# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProtectedBranches, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let(:protected_name) { 'feature' }
  let(:branch_name) { protected_name }
  let!(:protected_branch) do
    create(:protected_branch, project: project, name: protected_name)
  end

  describe "GET /projects/:id/protected_branches/:branch" do
    let(:route) { "/projects/#{project.id}/protected_branches/#{branch_name}" }

    shared_examples_for 'protected branch' do
      it 'returns the protected branch' do
        get api(route, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['unprotect_access_levels']).to eq([])
        expect(json_response).to include('inherited')
      end

      context 'with per user/group access levels' do
        let(:push_user) { create(:user) }
        let(:merge_group) { create(:group) }
        let(:unprotect_group) { create(:group) }

        before do
          project.add_developer(push_user)
          project.project_group_links.create!(group: merge_group)
          project.project_group_links.create!(group: unprotect_group)
          protected_branch.push_access_levels.create!(user: push_user)
          protected_branch.merge_access_levels.create!(group: merge_group)
          protected_branch.unprotect_access_levels.create!(group: unprotect_group)
        end

        it 'returns access level details' do
          get api(route, user)

          push_user_ids = json_response['push_access_levels'].map { |level| level['user_id'] }
          merge_group_ids = json_response['merge_access_levels'].map { |level| level['group_id'] }
          unprotect_group_ids = json_response['unprotect_access_levels'].map { |level| level['group_id'] }

          expect(response).to have_gitlab_http_status(:ok)
          expect(push_user_ids).to include(push_user.id)
          expect(merge_group_ids).to include(merge_group.id)
          expect(unprotect_group_ids).to include(unprotect_group.id)
        end
      end
    end

    context 'when authenticated as a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it_behaves_like 'protected branch'

      context 'when protected branch contains a wildcard' do
        let(:protected_name) { 'feature*' }

        it_behaves_like 'protected branch'
      end

      context 'when protected branch contains a period' do
        let(:protected_name) { 'my.feature' }

        it_behaves_like 'protected branch'
      end

      context 'when unprotect_access_level is set to DEVELOPER' do
        let(:protected_branch) do
          create(:protected_branch, :developers_can_unprotect, project: project, name: protected_name)
        end

        it 'unprotect_access_level is returned as DEVELOPER' do
          get api(route, user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['unprotect_access_levels'].first['access_level_description'])
            .to eq('Developers + Maintainers')
        end
      end
    end

    context 'when authenticated as a developer' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'protected branch'
    end

    context 'when authenticated as a guest' do
      before do
        project.add_guest(user)
      end

      it_behaves_like '403 response' do
        let(:request) { get api(route, user) }
      end
    end
  end

  describe "PATCH /projects/:id/protected_branches/:branch" do
    let(:route) { "/projects/#{project.id}/protected_branches/#{branch_name}" }

    context 'when authenticated as a maintainer' do
      before do
        project.add_maintainer(user)
        protected_branch.unprotect_access_levels << create(:protected_branch_unprotect_access_level)
      end

      let(:push_access_level) { protected_branch.push_access_levels.first }
      let(:merge_access_level) { protected_branch.merge_access_levels.first }
      let(:unprotect_access_level) { protected_branch.unprotect_access_levels.first }

      where(:key, :access_level_record, :access_level_param, :new_access_level) do
        [
          ['push_access_levels', ref(:push_access_level), 'allowed_to_push', 30],
          ['merge_access_levels', ref(:merge_access_level), 'allowed_to_merge', 30],
          ['unprotect_access_levels', ref(:unprotect_access_level), 'allowed_to_unprotect', 40]
        ]
      end

      with_them do
        it 'creates an access level' do
          params = {}
          params[access_level_param] =
            [
              {
                access_level: new_access_level,
                user_id: user.id
              }
            ]
          patch api(route, user), params: params
          expect(response).to have_gitlab_http_status(:ok)
          access_levels = json_response[key].map do |access_level|
            access_level['access_level']
          end

          expect(access_levels).to match_array [30, 40]
          expect(json_response[key].last['user_id']).to eq(user.id)
        end

        it 'updates an existing access level' do
          params = {}
          params[access_level_param] =
            [
              {
                id: access_level_record.id,
                access_level: new_access_level,
                user_id: user.id
              }
            ]
          patch api(route, user), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response[key].length).to eq(1)
          expect(json_response[key].last['access_level']).to eq(new_access_level)
          expect(json_response[key].last['user_id']).to eq(user.id)
        end

        it 'deletes an existing access level' do
          params = {}
          params[access_level_param] =
            [
              {
                id: access_level_record.id,
                _destroy: true
              }
            ]
          patch api(route, user), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response[key].length).to eq(0)
        end

        context 'when no access levels are sent' do
          it 'does not update with default access levels' do
            patch api(route, user)
            expect(json_response[key].length).to eq(1)
            expect(json_response[key].last['access_level']).to eq(access_level_record.access_level)
          end
        end
      end

      context "when the feature is enabled" do
        before do
          stub_licensed_features(code_owner_approval_required: true)
        end

        it "updates the protected branch" do
          expect do
            patch api(route, user), params: { code_owner_approval_required: true }
          end.to change { protected_branch.reload.code_owner_approval_required }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['code_owner_approval_required']).to eq(true)
        end
      end

      context "when the feature is disabled" do
        before do
          stub_licensed_features(code_owner_approval_required: false)
        end

        it "does not change the protected branch" do
          expect do
            patch api(route, user), params: { code_owner_approval_required: true }
          end.not_to change { protected_branch.reload.code_owner_approval_required }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'when authenticated as a developer' do
      before do
        project.add_developer(user)
      end

      it "returns a 403 response" do
        patch api(route, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as a guest' do
      before do
        project.add_guest(user)
      end

      it "returns a 403 response" do
        patch api(route, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'POST /projects/:id/protected_branches' do
    let(:branch_name) { 'new_branch' }
    let(:post_endpoint) { api("/projects/#{project.id}/protected_branches", user) }

    def expect_protection_to_be_successful
      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['name']).to eq(branch_name)
    end

    context 'when authenticated as a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it 'protects a single branch' do
        post post_endpoint, params: { name: branch_name }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['unprotect_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
      end

      it 'protects a single branch and only admins can unprotect' do
        post post_endpoint, params: { name: branch_name, unprotect_access_level: Gitlab::Access::ADMIN }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['name']).to eq(branch_name)
        expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
        expect(json_response['merge_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
        expect(json_response['unprotect_access_levels'][0]['access_level']).to eq(Gitlab::Access::ADMIN)
      end

      it 'no access is not a valid access level' do
        post post_endpoint, params: { name: branch_name, unprotect_access_level: Gitlab::Access::NO_ACCESS }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(response.body).to include('unprotect_access_level does not have a valid value')
      end

      context "code_owner_approval_required" do
        context "when feature is enabled" do
          before do
            stub_licensed_features(code_owner_approval_required: true)
          end

          it "sets :code_owner_approval_required to true when the param is true" do
            expect(project.protected_branches.find_by_name(branch_name)).to be_nil

            post post_endpoint, params: { name: branch_name, code_owner_approval_required: true }

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response["code_owner_approval_required"]).to eq(true)

            new_branch = project.protected_branches.find_by_name(branch_name)
            expect(new_branch.code_owner_approval_required).to be_truthy
            expect(new_branch[:code_owner_approval_required]).to be_truthy
          end

          it "sets :code_owner_approval_required to false when the param is false" do
            expect(project.protected_branches.find_by_name(branch_name)).to be_nil

            post post_endpoint, params: { name: branch_name, code_owner_approval_required: false }

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response["code_owner_approval_required"]).to eq(false)

            new_branch = project.protected_branches.find_by_name(branch_name)
            expect(new_branch.code_owner_approval_required).to be_falsy
            expect(new_branch[:code_owner_approval_required]).to be_falsy
          end
        end

        context "when feature is not enabled" do
          it "sets :code_owner_approval_required to false when the param is false" do
            expect(project.protected_branches.find_by_name(branch_name)).to be_nil

            post post_endpoint, params: { name: branch_name, code_owner_approval_required: true }

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response["code_owner_approval_required"]).to eq(false)

            new_branch = project.protected_branches.find_by_name(branch_name)
            expect(new_branch.code_owner_approval_required).to be_falsy
            expect(new_branch[:code_owner_approval_required]).to be_falsy
          end
        end
      end

      context 'with granular access' do
        let(:invited_group) do
          create(:project_group_link, project: project).group
        end

        let(:project_member) do
          create(:project_member, project: project).user
        end

        it 'can protect a branch while allowing an individual user to push' do
          push_user = project_member

          post post_endpoint, params: { name: branch_name, allowed_to_push: [{ user_id: push_user.id }] }

          expect_protection_to_be_successful
          expect(json_response['push_access_levels'][0]['user_id']).to eq(push_user.id)
        end

        it 'can protect a branch while allowing an individual user to merge' do
          merge_user = project_member

          post post_endpoint, params: { name: branch_name, allowed_to_merge: [{ user_id: merge_user.id }] }

          expect_protection_to_be_successful
          expect(json_response['merge_access_levels'][0]['user_id']).to eq(merge_user.id)
        end

        it 'can protect a branch while allowing an individual user to unprotect' do
          unprotect_user = project_member

          post post_endpoint, params: { name: branch_name, allowed_to_unprotect: [{ user_id: unprotect_user.id }] }

          expect_protection_to_be_successful
          expect(json_response['unprotect_access_levels'][0]['user_id']).to eq(unprotect_user.id)
        end

        it 'can protect a branch while allowing a group to push' do
          push_group = invited_group

          post post_endpoint, params: { name: branch_name, allowed_to_push: [{ group_id: push_group.id }] }

          expect_protection_to_be_successful
          expect(json_response['push_access_levels'][0]['group_id']).to eq(push_group.id)
        end

        it 'can protect a branch while allowing a group to merge' do
          merge_group = invited_group

          post post_endpoint, params: { name: branch_name, allowed_to_merge: [{ group_id: merge_group.id }] }

          expect_protection_to_be_successful
          expect(json_response['merge_access_levels'][0]['group_id']).to eq(merge_group.id)
        end

        it 'can protect a branch while allowing a group to unprotect' do
          unprotect_group = invited_group

          post post_endpoint, params: { name: branch_name, allowed_to_unprotect: [{ group_id: unprotect_group.id }] }

          expect_protection_to_be_successful
          expect(json_response['unprotect_access_levels'][0]['group_id']).to eq(unprotect_group.id)
        end

        it "fails if users don't all have access to the project" do
          push_user = create(:user)

          post post_endpoint, params: { name: branch_name, allowed_to_merge: [{ user_id: push_user.id }] }

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message'][0]).to match(/is not a member of the project/)
        end

        it "fails if groups aren't all invited to the project" do
          merge_group = create(:group)

          post post_endpoint, params: { name: branch_name, allowed_to_merge: [{ group_id: merge_group.id }] }

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message'][0]).to match(/does not have access to the project/)
        end

        it 'avoids creating default access levels unless necessary' do
          push_user = project_member

          post post_endpoint, params: { name: branch_name, allowed_to_push: [{ user_id: push_user.id }] }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['push_access_levels'].count).to eq(1)
          expect(json_response['merge_access_levels'].count).to eq(1)
          expect(json_response['push_access_levels'][0]['user_id']).to eq(push_user.id)
          expect(json_response['push_access_levels'][0]['access_level']).to eq(Gitlab::Access::MAINTAINER)
        end

        context 'when protected_refs_for_users feature is not available' do
          before do
            stub_licensed_features(protected_refs_for_users: false)
          end

          it 'cannot protect a branch for a user or group only' do
            allowed_to_create_param = [{ group_id: invited_group.id, user_id: project_member.id }]
            post post_endpoint, params: { name: branch_name, allowed_to_push: allowed_to_create_param }

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
          end
        end
      end
    end

    context 'when authenticated as a developer' do
      before do
        project.add_developer(user)
      end

      it 'returns a 403 response' do
        post post_endpoint, params: { name: branch_name }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as a guest' do
      before do
        project.add_guest(user)
      end

      it 'returns a 403 response' do
        post post_endpoint, params: { name: branch_name }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
