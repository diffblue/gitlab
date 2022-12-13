# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::MergeRequestApprovalSettings, feature_category: :source_code_management do
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, group: group) }
  let_it_be(:setting) { create(:group_merge_request_approval_setting, group: group) }

  shared_examples "resolvable" do
    using RSpec::Parameterized::TableSyntax

    where(:instance_prevents_approval, :group_allows_approval, :value, :locked, :inherited_from) do
      true  | true  | false | true  | 'instance'
      true  | false | false | true  | 'instance'
      false | true  | true  | false | nil
      false | false | false | false | nil
    end

    with_them do
      before do
        stub_ee_application_setting(instance_flag => instance_prevents_approval)
        group.group_merge_request_approval_setting.update!(group_flag => group_allows_approval)

        get api(url, user)
      end

      let(:object) { json_response[group_flag.to_s] }

      it 'has the correct value' do
        expect(object['value']).to eq(value)
      end

      it 'has the correct locked status' do
        expect(object['locked']).to eq(locked)
      end

      it 'has the correct inheritance' do
        expect(object['inherited_from']).to eq(inherited_from)
      end
    end
  end

  describe 'GET /groups/:id/merge_request_approval_settings' do
    let(:url) { "/groups/#{group.id}/merge_request_approval_setting" }

    context 'when the user is authorised' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
          .with(user, :admin_merge_request_approval_settings, group)
          .and_return(true)
      end

      context 'allow_author_approval values' do
        let(:instance_flag) { :prevent_merge_requests_author_approval }
        let(:group_flag) { :allow_author_approval }

        it_behaves_like 'resolvable'
      end

      context 'allow_committer_approval values' do
        let(:instance_flag) { :prevent_merge_requests_committers_approval }
        let(:group_flag) { :allow_committer_approval }

        it_behaves_like 'resolvable'
      end

      context 'allow_overrides_to_approver_list_per_merge_request values' do
        let(:instance_flag) { :disable_overriding_approvers_per_merge_request }
        let(:group_flag) { :allow_overrides_to_approver_list_per_merge_request }

        it_behaves_like 'resolvable'
      end

      it 'matches the response schema' do
        get api(url, user)

        expect(response).to match_response_schema('public_api/v4/group_merge_request_approval_settings', dir: 'ee')
      end

      context 'when the group does not have existing settings' do
        before do
          group.group_merge_request_approval_setting.delete
        end

        it 'returns in-memory default settings', :aggregate_failures do
          get api(url, user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['allow_author_approval']['value']).to eq(true)
          expect(json_response['allow_committer_approval']['value']).to eq(true)
          expect(json_response['allow_overrides_to_approver_list_per_merge_request']['value']).to eq(true)
          expect(json_response['retain_approvals_on_push']['value']).to eq(true)
          expect(json_response['selective_code_owner_removals']['value']).to eq(false)
          expect(json_response['require_password_to_approve']['value']).to eq(false)
        end
      end

      context 'when the user is not authorised' do
        before do
          allow(Ability).to receive(:allowed?)
            .with(user, :admin_merge_request_approval_settings, group)
            .and_return(false)
        end

        it 'returns 403 status' do
          get api(url, user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  describe 'PUT /groups/:id/merge_request_approval_setting' do
    let(:url) { "/groups/#{group.id}/merge_request_approval_setting" }
    let(:params) { { allow_author_approval: true } }

    before do
      allow(Ability).to receive(:allowed?).and_call_original
    end

    context 'when the user is authorised' do
      before do
        allow(Ability).to receive(:allowed?)
          .with(user, :admin_merge_request_approval_settings, group)
          .and_return(true)
      end

      it 'returns 200 status with correct response body', :aggregate_failures do
        put api(url, user), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['allow_author_approval']['value']).to eq(true)
      end

      it 'matches the response schema' do
        put api(url, user), params: params

        expect(response).to match_response_schema('public_api/v4/group_merge_request_approval_settings', dir: 'ee')
      end

      context 'when update fails' do
        let(:params) { { allow_author_approval: 45 } }

        it 'returns 400 status', :aggregate_failures do
          put api(url, user), params: params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to match(/allow_.*_approval is invalid/)
        end
      end

      context 'when invalid params' do
        let(:params) { {} }

        it 'returns 400 status with error message', :aggregate_failures do
          put api(url, user), params: params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to match(/at least one parameter must be provided/)
        end
      end
    end

    context 'when the user is not authorised' do
      before do
        allow(Ability).to receive(:allowed?)
          .with(user, :admin_merge_request_approval_settings, group)
          .and_return(false)
      end

      it 'returns 403 status' do
        put api(url, user), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'GET /projects/:id/merge_request_approval_settings' do
    let(:url) { "/projects/#{project.id}/merge_request_approval_setting" }

    before do
      group.add_owner(user)
      allow(Ability).to receive(:allowed?).and_call_original
      stub_licensed_features(merge_request_approvers: true)
      allow(Ability).to receive(:allowed?)
                          .with(user, :admin_merge_request_approval_settings, project)
                          .and_return(true)
    end

    it 'matches the response schema' do
      get api(url, user)

      expect(response).to match_response_schema('public_api/v4/group_merge_request_approval_settings', dir: 'ee')
    end

    context 'when the project does not have existing settings' do
      before do
        project.update!(
          merge_requests_author_approval: nil,
          merge_requests_disable_committers_approval: nil,
          disable_overriding_approvers_per_merge_request: nil,
          reset_approvals_on_push: nil,
          require_password_to_approve: nil
        )
      end

      it 'returns in-memory default settings', :aggregate_failures do
        get api(url, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['allow_author_approval']['value']).to eq(false)
        expect(json_response['allow_committer_approval']['value']).to eq(false)
        expect(json_response['allow_overrides_to_approver_list_per_merge_request']['value']).to eq(false)
        expect(json_response['retain_approvals_on_push']['value']).to eq(false)
        expect(json_response['selective_code_owner_removals']['value']).to eq(false)
        expect(json_response['require_password_to_approve']['value']).to eq(false)
      end
    end
  end

  describe 'PUT /projects/:id/merge_request_approval_settings' do
    let(:url) { "/projects/#{project.id}/merge_request_approval_setting" }
    let(:params) { { retain_approvals_on_push: false } }

    before do
      group.add_owner(user)
      allow(Ability).to receive(:allowed?).and_call_original
      stub_licensed_features(merge_request_approvers: true)
      allow(Ability).to receive(:allowed?)
                          .with(user, :admin_merge_request_approval_settings, project)
                          .and_return(true)
      group.group_merge_request_approval_setting.delete
    end

    it 'matches the response schema and updates the params' do
      put api(url, user), params: params

      expect(project.reset_approvals_on_push).to be true

      expect(response).to match_response_schema('public_api/v4/group_merge_request_approval_settings', dir: 'ee')
    end

    context 'when enabling selective_code_owner_removals and retain_approvals_on_push' do
      let(:params) { { retain_approvals_on_push: true, selective_code_owner_removals: true } }

      it 'updates the params' do
        put api(url, user), params: params

        expect(response).to have_gitlab_http_status(:ok)

        project.reload
        expect(project.reset_approvals_on_push).to be false
        expect(project.project_setting.selective_code_owner_removals).to be true
      end
    end

    context 'when enabling selective_code_owner_removals with retain_approvals_on_push disabled' do
      let(:params) { { selective_code_owner_removals: true } }

      it 'returns error response and does not update the params' do
        put api(url, user), params: params

        expect(response).to have_gitlab_http_status(:bad_request)

        project.reload
        expect(project.project_setting.selective_code_owner_removals).to be false
      end
    end
  end
end
