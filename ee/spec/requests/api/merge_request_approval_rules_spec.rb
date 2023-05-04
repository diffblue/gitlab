# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::MergeRequestApprovalRules, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let(:project) { create(:project, :public, :repository, creator: user, namespace: user.namespace) }
  let(:merge_request) { create(:merge_request, author: user, source_project: project, target_project: project) }

  shared_examples_for 'a protected API endpoint for merge request approval rule action' do
    context 'disable_overriding_approvers_per_merge_request is set to true' do
      before do
        project.update!(disable_overriding_approvers_per_merge_request: true)

        action
      end

      it 'responds with 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'disable_overriding_approvers_per_merge_request is set to false' do
      before do
        project.update!(disable_overriding_approvers_per_merge_request: false)

        action
      end

      context 'user cannot update merge request' do
        let(:current_user) { other_user }

        it 'responds with 403' do
          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  shared_examples_for 'a protected API endpoint that only allows action on regular merge request approval rule' do
    context 'approval rule is not a regular type' do
      let(:approval_rule) { create(:code_owner_rule, merge_request: merge_request) }

      it 'responds with 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  shared_context 'getting approval rule' do
    let(:approver) { create(:user) }
    let(:group) { create(:group) }
    let(:source_rule) { nil }
    let(:users) { [approver] }
    let(:groups) { [group] }
    let(:current_user) { other_user }

    let!(:mr_approval_rule) do
      create(
        :approval_merge_request_rule,
        merge_request: merge_request,
        approval_project_rule: source_rule,
        users: users,
        groups: groups
      )
    end
  end

  shared_examples_for 'getting approval rule/s' do
    context 'user cannot read merge request' do
      before do
        project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)

        get api(url, other_user)
      end

      it 'responds with 403' do
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'user can read merge request' do
      before do
        group.add_developer(approver)
        merge_request.approvals.create!(user: approver)

        get api(url, current_user)
      end

      it 'matches the response schema' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema(schema_path, dir: 'ee')

        rule = get_rule.call(json_response)

        expect(rule['name']).to eq(mr_approval_rule.name)
        expect(rule['approvals_required']).to eq(mr_approval_rule.approvals_required)
        expect(rule['rule_type']).to eq(mr_approval_rule.rule_type)
        expect(rule['section']).to be_nil
        expect(rule['contains_hidden_groups']).to eq(false)
        expect(rule['source_rule']).to be_nil
        expect(rule['eligible_approvers']).to match_array([hash_including('id' => approver.id)])
        expect(rule['users']).to match_array([hash_including('id' => approver.id)])
        expect(rule['groups']).to match_array([hash_including('id' => group.id)])
      end

      context 'groups contain private groups' do
        let(:group) { create(:group, :private) }

        context 'current_user cannot see private group' do
          it 'hides private group' do
            rule = get_rule.call(json_response)

            expect(rule['contains_hidden_groups']).to eq(true)
            expect(rule['groups']).to be_empty
          end
        end

        context 'current_user can see private group' do
          let(:current_user) { approver }

          it 'shows private group' do
            rule = get_rule.call(json_response)

            expect(rule['contains_hidden_groups']).to eq(false)
            expect(rule['groups']).to match_array([hash_including('id' => group.id)])
          end
        end
      end

      context 'has existing merge request rule that overrides a project-level rule' do
        let(:source_rule) { create(:approval_project_rule, project: project) }

        it 'includes source_rule' do
          rule = get_rule.call(json_response)

          expect(rule['source_rule']['approvals_required']).to eq(source_rule.approvals_required)
        end
      end
    end
  end

  describe 'GET /projects/:id/merge_requests/:merge_request_iid/approval_rules/:approval_rule_id' do
    include_context "getting approval rule"

    let(:url) { "/projects/#{project.id}/merge_requests/#{merge_request.iid}/approval_rules/#{mr_approval_rule.id}" }
    let(:schema_path) { 'public_api/v4/merge_request_approval_rule' }
    let(:get_rule) { -> (response) { response } }

    it_behaves_like 'getting approval rule/s'
  end

  describe 'GET /projects/:id/merge_requests/:merge_request_iid/approval_rules' do
    include_context "getting approval rule"

    let(:url) { "/projects/#{project.id}/merge_requests/#{merge_request.iid}/approval_rules" }
    let(:schema_path) { 'public_api/v4/merge_request_approval_rules' }
    let(:get_rule) { -> (response) { response.first } }

    it_behaves_like 'getting approval rule/s'

    context 'user can read merge request' do
      before do
        group.add_developer(approver)
        merge_request.approvals.create!(user: approver)
        get api(url, current_user)
      end

      it 'returns the correct amount of rules' do
        rules = json_response

        expect(response).to include_pagination_headers
        expect(rules.size).to eq(1)
      end
    end
  end

  describe 'POST /projects/:id/merge_requests/:merge_request_iid/approval_rules' do
    let(:current_user) { user }
    let(:url) { "/projects/#{project.id}/merge_requests/#{merge_request.iid}/approval_rules" }
    let(:approver) { create(:user) }
    let(:other_approver) { create(:user) }
    let(:group) { create(:group) }
    let(:other_group) { create(:group) }
    let(:approval_project_rule_id) { nil }
    let(:approver_params) do
      {
        user_ids: user_ids,
        usernames: usernames,
        group_ids: group_ids
      }
    end

    let(:user_ids) { [] }
    let(:group_ids) { [] }
    let(:usernames) { [] }

    let(:params) do
      {
        name: 'Test',
        approvals_required: 1,
        approval_project_rule_id: approval_project_rule_id
      }.merge(approver_params)
    end

    let(:action) { post api(url, current_user), params: params }

    it_behaves_like 'a protected API endpoint for merge request approval rule action'

    context 'when user can update merge request and approval rules can be overridden' do
      before do
        project.update!(disable_overriding_approvers_per_merge_request: false)
        project.add_developer(approver)
        project.add_developer(other_approver)
        group.add_developer(approver)
        other_group.add_developer(other_approver)

        action
      end

      it 'matches the response schema' do
        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/merge_request_approval_rule', dir: 'ee')

        rule = json_response

        expect(rule['name']).to eq(params[:name])
        expect(rule['approvals_required']).to eq(params[:approvals_required])
        expect(rule['rule_type']).to eq('any_approver')
        expect(rule['contains_hidden_groups']).to eq(false)
        expect(rule['source_rule']).to be_nil
        expect(rule['eligible_approvers']).to be_empty
        expect(rule['users']).to be_empty
        expect(rule['groups']).to be_empty
      end

      context 'users are passed' do
        let(:user_ids) { "#{approver.id},#{other_approver.id}" }

        it 'includes users' do
          rule = json_response

          expect(rule['eligible_approvers'].pluck('id')).to contain_exactly(approver.id, other_approver.id)
          expect(rule['users'].pluck('id')).to contain_exactly(approver.id, other_approver.id)
        end
      end

      context 'groups are passed' do
        let(:group_ids) { "#{group.id},#{other_group.id}" }

        it 'includes groups' do
          rule = json_response

          expect(rule['eligible_approvers'].pluck('id')).to contain_exactly(approver.id, other_approver.id)
          expect(rule['groups'].pluck('id')).to contain_exactly(group.id, other_group.id)
        end
      end

      context 'usernames are passed' do
        let(:usernames) { "#{approver.username}, #{other_approver.username}" }

        it 'includes users' do
          rule = json_response

          expect(rule['eligible_approvers'].pluck('id')).to contain_exactly(approver.id, other_approver.id)
          expect(rule['users'].pluck('id')).to contain_exactly(approver.id, other_approver.id)
        end
      end

      context 'usernames and user_ids are passed' do
        let(:user_ids) { approver.id }
        let(:usernames) { other_approver.username }

        it 'includes users' do
          rule = json_response

          expect(rule['eligible_approvers'].pluck('id')).to contain_exactly(approver.id, other_approver.id)
          expect(rule['users'].pluck('id')).to contain_exactly(approver.id, other_approver.id)
        end
      end

      context 'approval_project_rule_id is passed' do
        let(:approval_project_rule) do
          create(
            :approval_project_rule,
            project: project,
            users: [approver],
            groups: [group]
          )
        end

        let(:approval_project_rule_id) { approval_project_rule.id }

        context 'with blank approver params' do
          it 'copies the attributes from the project rule except approvers' do
            rule = json_response

            expect(rule['name']).to eq(approval_project_rule.name)
            expect(rule['approvals_required']).to eq(params[:approvals_required])
            expect(rule['source_rule']['approvals_required']).to eq(approval_project_rule.approvals_required)
            expect(rule['eligible_approvers']).to eq([])
            expect(rule['users']).to eq([])
            expect(rule['groups']).to eq([])
          end
        end

        context 'with omitted approver params' do
          let(:approver_params) { {} }

          it 'copies the attributes from the project rule except approvals_required' do
            rule = json_response

            expect(rule['name']).to eq(approval_project_rule.name)
            expect(rule['approvals_required']).to eq(params[:approvals_required])
            expect(rule['source_rule']['approvals_required']).to eq(approval_project_rule.approvals_required)
            expect(rule['eligible_approvers']).to match([hash_including('id' => approver.id)])
            expect(rule['users']).to match([hash_including('id' => approver.id)])
            expect(rule['groups']).to match([hash_including('id' => group.id)])
          end
        end
      end
    end
  end

  describe 'PUT /projects/:id/merge_requests/:merge_request_iid/approval_rules/:approval_rule_id' do
    let(:current_user) { user }
    let(:existing_approver) { create(:user) }
    let(:existing_group) { create(:group) }

    let(:approval_rule) do
      create(
        :approval_merge_request_rule,
        merge_request: merge_request,
        name: 'Old Name',
        approvals_required: 2,
        users: [existing_approver],
        groups: [existing_group]
      )
    end

    let(:url) { "/projects/#{project.id}/merge_requests/#{merge_request.iid}/approval_rules/#{approval_rule.id}" }
    let(:new_approver) { create(:user) }
    let(:new_group) { create(:group) }
    let(:user_ids) { [] }
    let(:group_ids) { [] }
    let(:usernames) { [] }
    let(:remove_hidden_groups) { nil }
    let(:other_approver) { create(:user) }
    let(:other_group) { create(:group) }

    let(:params) do
      {
        name: 'Test',
        approvals_required: 1,
        user_ids: user_ids,
        group_ids: group_ids,
        usernames: usernames,
        remove_hidden_groups: remove_hidden_groups
      }
    end

    let(:action) { put api(url, current_user), params: params }

    it_behaves_like 'a protected API endpoint for merge request approval rule action'

    context 'when user can update merge request and approval rules can be overridden' do
      before do
        project.update!(disable_overriding_approvers_per_merge_request: false)
        project.add_developer(existing_approver)
        project.add_developer(new_approver)
        project.add_developer(other_approver)
        existing_group.add_developer(existing_approver)
        new_group.add_developer(new_approver)
        other_group.add_developer(other_approver)

        action
      end

      it_behaves_like 'a protected API endpoint that only allows action on regular merge request approval rule'

      it 'matches the response schema' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/merge_request_approval_rule', dir: 'ee')

        rule = json_response

        expect(rule['name']).to eq(params[:name])
        expect(rule['approvals_required']).to eq(params[:approvals_required])
        expect(rule['rule_type']).to eq(approval_rule.rule_type)
        expect(rule['contains_hidden_groups']).to eq(false)
        expect(rule['source_rule']).to be_nil
        expect(rule['eligible_approvers']).to be_empty
        expect(rule['users']).to be_empty
        expect(rule['groups']).to be_empty
      end

      context 'users are passed' do
        let(:user_ids) { "#{new_approver.id},#{existing_approver.id}" }

        it 'changes users' do
          rule = json_response

          expect(rule['eligible_approvers'].pluck('id')).to contain_exactly(new_approver.id, existing_approver.id)
          expect(rule['users'].pluck('id')).to contain_exactly(new_approver.id, existing_approver.id)
        end
      end

      context 'groups are passed' do
        let(:group_ids) { "#{new_group.id},#{other_group.id}" }

        it 'changes groups' do
          rule = json_response

          expect(rule['eligible_approvers'].pluck('id')).to contain_exactly(new_approver.id, other_approver.id)
          expect(rule['groups'].pluck('id')).to contain_exactly(new_group.id, other_group.id)
        end
      end

      context 'remove_hidden_groups is passed' do
        let(:existing_group) { create(:group, :private) }

        context 'when set to true' do
          let(:remove_hidden_groups) { true }

          it 'removes the existing private group' do
            expect(approval_rule.reload.groups).not_to include(existing_group)
          end
        end

        context 'when set to false' do
          let(:remove_hidden_groups) { false }

          it 'does not remove the existing private group' do
            expect(approval_rule.reload.groups).to include(existing_group)
          end
        end
      end

      context 'usernames are passed' do
        let(:usernames) { "#{new_approver.username},#{existing_approver.username}" }

        it 'includes users' do
          rule = json_response

          expect(rule['eligible_approvers'].pluck('id')).to contain_exactly(new_approver.id, existing_approver.id)
          expect(rule['users'].pluck('id')).to contain_exactly(new_approver.id, existing_approver.id)
        end
      end
    end
  end

  describe 'DELETE /projects/:id/merge_requests/:merge_request_iid/approval_rules/:approval_rule_id' do
    let(:current_user) { user }
    let(:approval_rule) { create(:approval_merge_request_rule, merge_request: merge_request) }
    let(:url) { "/projects/#{project.id}/merge_requests/#{merge_request.iid}/approval_rules/#{approval_rule.id}" }
    let(:action) { delete api(url, current_user) }

    it_behaves_like 'a protected API endpoint for merge request approval rule action'

    context 'when user can update merge request and approval rules can be overridden' do
      before do
        project.update!(disable_overriding_approvers_per_merge_request: false)

        action
      end

      it_behaves_like 'a protected API endpoint that only allows action on regular merge request approval rule'

      it 'responds with 204' do
        expect(response).to have_gitlab_http_status(:no_content)
      end
    end
  end
end
