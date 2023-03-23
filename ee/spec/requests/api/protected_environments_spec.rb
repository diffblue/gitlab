# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProtectedEnvironments, feature_category: :continuous_delivery do
  include AccessMatchersForRequest

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }

  let(:user) { create(:user) }
  let(:protected_environment_name) { 'production' }

  let!(:project_protected_environment) do
    create(:protected_environment, :maintainers_can_deploy, :project_level,
           project: project, name: protected_environment_name, required_approval_count: 1)
  end

  let!(:group_protected_environment) do
    create(:protected_environment, :maintainers_can_deploy, :group_level,
           group: group, name: protected_environment_name, required_approval_count: 2)
  end

  shared_examples 'requests for non-maintainers' do
    it { expect { request }.to be_denied_for(:guest).of(project) }
    it { expect { request }.to be_denied_for(:developer).of(project) }
    it { expect { request }.to be_denied_for(:reporter).of(project) }
    it { expect { request }.to be_denied_for(:anonymous) }
  end

  shared_examples 'group-level request is disallowed for maintainer' do
    it { expect { request }.to be_denied_for(:maintainer).of(group) }
  end

  shared_examples 'group-level request is allowed for maintainer' do
    it { expect { request }.to be_allowed_for(:maintainer).of(group) }
  end

  shared_examples 'requests to update deploy access levels' do
    it 'updates the environment / creating deploy access level' do
      put request_url, params: {
        deploy_access_levels: [
          {
            user_id: user_id
          }
        ]
      }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
      expect(json_response['deploy_access_levels'].length).to eq(2)
      expect(json_response['deploy_access_levels'].last['user_id']).to eq(user_id)
    end

    it 'updates the environment / updating deploy access level' do
      put request_url, params: {
        deploy_access_levels: [
          {
            id: protected_environment.deploy_access_levels.last.id,
            user_id: user_id,
            access_level: nil
          }
        ]
      }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
      expect(json_response['deploy_access_levels'].length).to eq(1)
      expect(json_response['deploy_access_levels'].last['user_id']).to eq(user_id)
    end

    it 'updates the environment / deleting deploy access level / failed' do
      put request_url, params: {
        deploy_access_levels: [
          {
            id: protected_environment.deploy_access_levels.last.id,
            user_id: user_id,
            _destroy: true
          }
        ]
      }

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
      expect(json_response['message']).to include('Deploy access levels is too short (minimum is 1 character)')
    end

    it 'updates the environment / deleting deploy access level / succeed' do
      protected_environment.deploy_access_levels << build(:protected_environment_deploy_access_level)

      put request_url, params: {
        deploy_access_levels: [
          {
            id: protected_environment.deploy_access_levels.last.id,
            user_id: user_id,
            _destroy: true
          }
        ]
      }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
      expect(json_response['deploy_access_levels'].length).to eq(1)
    end

    it 'updates the environment / updating required approval count' do
      put request_url, params: {
        required_approval_count: 3
      }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
      expect(json_response['required_approval_count']).to eq(3)
    end
  end

  shared_examples 'requests to update approval rules' do
    it 'updates the environment / creating approval rule' do
      put request_url, params: {
        approval_rules: [
          {
            user_id: user_id
          }
        ]
      }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
      expect(json_response['approval_rules'].length).to eq(1)
      expect(json_response['approval_rules'].last['user_id']).to eq(user_id)
    end

    it 'updates the environment / updating approval rule' do
      create(:protected_environment_approval_rule, protected_environment: protected_environment, user_id: user.id)

      put request_url, params: {
        approval_rules: [
          {
            id: protected_environment.approval_rules.last.id,
            user_id: user_id,
            required_approvals: 2
          }
        ]
      }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
      expect(json_response['approval_rules'].length).to eq(1)
      expect(json_response['approval_rules'].last['user_id']).to eq(user_id)
      expect(json_response['approval_rules'].last['required_approvals']).to eq(2)
    end

    it 'updates the environment / deleting approval rule' do
      create(:protected_environment_approval_rule, protected_environment: protected_environment, user_id: user.id)

      put request_url, params: {
        approval_rules: [
          {
            id: protected_environment.approval_rules.last.id,
            user_id: user_id,
            _destroy: true
          }
        ]
      }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
      expect(json_response['approval_rules'].length).to eq(0)
    end
  end

  describe 'GET /projects/:id/protected_environments' do
    let(:route) { "/projects/#{project.id}/protected_environments" }
    let(:request) { get api(route, user), params: { per_page: 100 } }

    context 'when authenticated as a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it 'returns the protected environments' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array

        protected_environment_names = json_response.map { |x| x['name'] }
        expect(protected_environment_names).to match_array([protected_environment_name])
      end
    end

    it_behaves_like 'requests for non-maintainers'
  end

  describe 'GET /projects/:id/protected_environments/:environment' do
    let(:requested_environment_name) { protected_environment_name }
    let(:route) { "/projects/#{project.id}/protected_environments/#{requested_environment_name}" }
    let(:request) { get api(route, user) }

    context 'when authenticated as a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it 'returns the protected environment' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
        expect(json_response['name']).to eq(protected_environment_name)
        expect(json_response['deploy_access_levels'][0]['access_level']).to eq(::Gitlab::Access::MAINTAINER)
        expect(json_response['required_approval_count']).to eq(1)
      end

      context 'with multiple approval rules' do
        before do
          create(:protected_environment_approval_rule, :maintainer_access,
            protected_environment: project_protected_environment, required_approvals: 3,
            group_inheritance_type: ::ProtectedEnvironments::Authorizable::GROUP_INHERITANCE_TYPE[:ALL])
        end

        it 'returns the protected environment' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
          expect(json_response['name']).to eq(protected_environment_name)
          expect(json_response['deploy_access_levels'][0]['access_level']).to eq(::Gitlab::Access::MAINTAINER)
          expect(json_response['approval_rules'][0]['access_level']).to eq(::Gitlab::Access::MAINTAINER)
          expect(json_response['approval_rules'][0]['required_approvals']).to eq(3)
          expect(json_response['approval_rules'][0]['group_inheritance_type']).to eq(::ProtectedEnvironments::Authorizable::GROUP_INHERITANCE_TYPE[:ALL])
        end
      end

      context 'when protected environment does not exist' do
        let(:requested_environment_name) { 'unknown' }

        it_behaves_like '404 response' do
          let(:message) { '404 Not found' }
        end
      end
    end

    it_behaves_like 'requests for non-maintainers'
  end

  describe 'POST /projects/:id/protected_environments/' do
    let(:api_url) { api("/projects/#{project.id}/protected_environments/", user) }

    context 'when authenticated as a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it 'protects the environment with user allowed to deploy' do
        deployer = create(:user)
        project.add_developer(deployer)

        post api_url, params: { name: 'staging', deploy_access_levels: [{ user_id: deployer.id }], required_approval_count: 3 }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
        expect(json_response['name']).to eq('staging')
        expect(json_response['deploy_access_levels'].first['user_id']).to eq(deployer.id)
        expect(json_response['required_approval_count']).to eq(3)
      end

      it 'protects the environment with group allowed to deploy' do
        group = create(:project_group_link, project: project).group

        post api_url, params: { name: 'staging', deploy_access_levels: [{ group_id: group.id }] }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
        expect(json_response['name']).to eq('staging')
        expect(json_response['deploy_access_levels'].first['group_id']).to eq(group.id)
      end

      it 'protects the environment with maintainers allowed to deploy' do
        post api_url, params: { name: 'staging', deploy_access_levels: [{ access_level: Gitlab::Access::MAINTAINER }] }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
        expect(json_response['name']).to eq('staging')
        expect(json_response['deploy_access_levels'].first['access_level']).to eq(Gitlab::Access::MAINTAINER)
      end

      it 'returns 409 error if environment is already protected' do
        deployer = create(:user)
        project.add_developer(deployer)

        post api_url, params: { name: 'production', deploy_access_levels: [{ user_id: deployer.id }] }

        expect(response).to have_gitlab_http_status(:conflict)
      end

      it 'protects the environment and require approvals' do
        deployer = create(:user)
        project.add_developer(deployer)

        post api_url, params: { name: 'staging', deploy_access_levels: [{ user_id: deployer.id }],
                                approval_rules: [{ access_level: Gitlab::Access::MAINTAINER,
                                                   group_inheritance_type: ::ProtectedEnvironments::Authorizable::GROUP_INHERITANCE_TYPE[:ALL] }] }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
        expect(json_response['name']).to eq('staging')
        expect(json_response['deploy_access_levels'].first['user_id']).to eq(deployer.id)
        expect(json_response['approval_rules'].count).to eq(1)
        expect(json_response['approval_rules'].first['access_level']).to eq(Gitlab::Access::MAINTAINER)
        expect(json_response['approval_rules'].first['group_inheritance_type']).to eq(::ProtectedEnvironments::Authorizable::GROUP_INHERITANCE_TYPE[:ALL])
      end

      context 'without deploy_access_levels' do
        it_behaves_like '400 response' do
          let(:request) { post api_url, params: { name: 'staging' } }
        end
      end

      it 'returns error with invalid deploy access level' do
        post api_url, params: { name: 'staging', deploy_access_levels: [{ access_level: nil }] }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    it_behaves_like 'requests for non-maintainers' do
      let(:request) { post api_url, params: { name: 'staging' } }
    end
  end

  describe 'PUT /projects/:id/protected_environments/:name' do
    let(:api_url) { api("/projects/#{project.id}/protected_environments/#{project_protected_environment.name}", user) }
    let(:developer_access) { Gitlab::Access::DEVELOPER }

    context 'when authenticated as maintainer' do
      let_it_be(:deployer) { create(:user) }
      let_it_be(:group) { create(:project_group_link, project: project).group }

      before do
        project.add_maintainer(user)
        project.add_developer(deployer)
      end

      it_behaves_like 'requests to update deploy access levels' do
        let(:request_url) { api_url }
        let(:user_id) { deployer.id }
        let(:protected_environment) { project_protected_environment }
      end

      it_behaves_like 'requests to update approval rules' do
        let(:request_url) { api_url }
        let(:user_id) { deployer.id }
        let(:protected_environment) { project_protected_environment }
      end

      context 'with invalid deploy_access_level' do
        it 'returns error with invalid deploy access level' do
          put api_url, params: { deploy_access_levels: [{ access_level: nil }] }

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end

      context 'when protected environment does not exist' do
        let(:api_url) { api("/projects/#{project.id}/protected_environments/invalid", user) }

        it 'returns a not found error' do
          put api_url, params: { deploy_access_levels: [{ access_level: developer_access }] }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    it_behaves_like 'requests for non-maintainers' do
      let(:request) { put api_url, params: { name: 'production' } }
    end
  end

  describe 'DELETE /projects/:id/protected_environments/:environment' do
    let(:route) { "/projects/#{project.id}/protected_environments/production" }
    let(:request) { delete api(route, user) }

    context 'when authenticated as a maintainer' do
      before do
        project.add_maintainer(user)
      end

      it 'unprotects the environment' do
        expect do
          request
        end.to change { project.protected_environments.count }.by(-1)

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    it_behaves_like 'requests for non-maintainers'
  end

  describe 'GET /groups/:id/protected_environments' do
    let(:route) { "/groups/#{group.id}/protected_environments" }
    let(:request) { get api(route, user), params: { per_page: 100 } }

    it_behaves_like 'group-level request is disallowed for maintainer'

    context 'when authenticated as a owner' do
      before do
        group.add_owner(user)
      end

      it 'returns the protected environments' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array

        protected_environment_names = json_response.map { |x| x['name'] }
        expect(protected_environment_names).to match_array([protected_environment_name])
      end
    end
  end

  describe 'GET /groups/:id/protected_environments/:environment' do
    let(:requested_environment_name) { protected_environment_name }
    let(:route) { "/groups/#{group.id}/protected_environments/#{requested_environment_name}" }
    let(:request) { get api(route, user) }

    it_behaves_like 'group-level request is disallowed for maintainer'

    context 'when authenticated as a owner' do
      before do
        group.add_owner(user)
      end

      it 'returns the protected environment' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
        expect(json_response['name']).to eq(protected_environment_name)
        expect(json_response['deploy_access_levels'][0]['access_level']).to eq(::Gitlab::Access::MAINTAINER)
        expect(json_response['required_approval_count']).to eq(2)
      end

      context 'with multiple approval rules' do
        before do
          create(:protected_environment_approval_rule, :maintainer_access,
            protected_environment: group_protected_environment, required_approvals: 3)
        end

        it 'returns the protected environment' do
          request

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
          expect(json_response['name']).to eq(protected_environment_name)
          expect(json_response['deploy_access_levels'][0]['access_level']).to eq(::Gitlab::Access::MAINTAINER)
          expect(json_response['approval_rules'][0]['access_level']).to eq(::Gitlab::Access::MAINTAINER)
          expect(json_response['approval_rules'][0]['required_approvals']).to eq(3)
        end
      end

      context 'when protected environment does not exist' do
        let(:requested_environment_name) { 'unknown' }

        it_behaves_like '404 response' do
          let(:message) { '404 Not found' }
        end
      end
    end
  end

  describe 'POST /groups/:id/protected_environments/' do
    let(:api_url) { api("/groups/#{group.id}/protected_environments/", user) }

    it_behaves_like 'group-level request is disallowed for maintainer' do
      let(:request) { post api_url, params: { name: 'staging' } }
    end

    context 'when authenticated as a owner' do
      before do
        group.add_owner(user)
      end

      it 'protects the environment with user allowed to deploy' do
        deployer = create(:user)
        group.add_maintainer(deployer)

        post api_url, params: { name: 'staging', deploy_access_levels: [{ user_id: deployer.id }], required_approval_count: 3 }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
        expect(json_response['name']).to eq('staging')
        expect(json_response['deploy_access_levels'].first['user_id']).to eq(deployer.id)
        expect(json_response['required_approval_count']).to eq(3)
      end

      it 'protects the environment with group allowed to deploy' do
        subgroup = create(:group, parent: group)

        post api_url, params: { name: 'staging', deploy_access_levels: [{ group_id: subgroup.id }] }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
        expect(json_response['name']).to eq('staging')
        expect(json_response['deploy_access_levels'].first['group_id']).to eq(subgroup.id)
      end

      it 'protects the environment with shared group allowed to deploy' do
        shared_group = create(:group)
        create(:group_group_link, shared_group: group, shared_with_group: shared_group)

        post api_url, params: { name: 'staging', deploy_access_levels: [{ group_id: shared_group.id }] }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
        expect(json_response['name']).to eq('staging')
        expect(json_response['deploy_access_levels'].first['group_id']).to eq(shared_group.id)
      end

      it 'protects the environment with maintainers allowed to deploy' do
        post api_url, params: { name: 'staging', deploy_access_levels: [{ access_level: Gitlab::Access::MAINTAINER }] }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
        expect(json_response['name']).to eq('staging')
        expect(json_response['deploy_access_levels'].first['access_level']).to eq(Gitlab::Access::MAINTAINER)
      end

      it 'protects the environment with group allowed to deploy with inheritance', :aggregate_failures do
        subgroup = create(:group, parent: group)

        post api_url, params: { name: 'staging', deploy_access_levels: [{ group_id: subgroup.id,
                                                                          group_inheritance_type: ::ProtectedEnvironments::Authorizable::GROUP_INHERITANCE_TYPE[:ALL] }] }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
        expect(json_response['name']).to eq('staging')
        expect(json_response['deploy_access_levels'].first['group_id']).to eq(subgroup.id)
        expect(json_response['deploy_access_levels'].first['group_inheritance_type']).to eq(::ProtectedEnvironments::Authorizable::GROUP_INHERITANCE_TYPE[:ALL])
      end

      it 'protects the environment and require approvals' do
        deployer = create(:user)
        project.add_developer(deployer)

        post api_url, params: { name: 'staging', deploy_access_levels: [{ access_level: Gitlab::Access::MAINTAINER }],
                                approval_rules: [{ access_level: Gitlab::Access::DEVELOPER }] }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
        expect(json_response['name']).to eq('staging')
        expect(json_response['deploy_access_levels'].first['access_level']).to eq(Gitlab::Access::MAINTAINER)
        expect(json_response['approval_rules'].count).to eq(1)
        expect(json_response['approval_rules'].first['access_level']).to eq(Gitlab::Access::DEVELOPER)
      end

      it 'returns 409 error if environment is already protected' do
        deployer = create(:user)
        group.add_developer(deployer)

        post api_url, params: { name: 'production', deploy_access_levels: [{ user_id: deployer.id }] }

        expect(response).to have_gitlab_http_status(:conflict)
      end

      context 'without deploy_access_levels' do
        it_behaves_like '400 response' do
          let(:request) { post api_url, params: { name: 'staging' } }
        end
      end

      it 'returns error with invalid deploy access level' do
        post api_url, params: { name: 'staging', deploy_access_levels: [{ access_level: nil }] }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT /groups/:id/protected_environments/:name' do
    let(:api_url) { api("/groups/#{group.id}/protected_environments/#{group_protected_environment.name}", user) }
    let(:maintainer_access) { Gitlab::Access::MAINTAINER }

    it_behaves_like 'group-level request is disallowed for maintainer' do
      let(:request) { put api_url, params: { name: 'production' } }
    end

    context 'when authenticated as a owner' do
      let_it_be(:deployer) { create(:user) }
      let_it_be(:shared_group) { create(:group) }
      let_it_be(:subgroup) { create(:group, parent: group) }

      before do
        group.add_owner(user)
        group.add_maintainer(deployer)

        create(:group_group_link, shared_group: group, shared_with_group: shared_group)
      end

      it_behaves_like 'requests to update deploy access levels' do
        let(:request_url) { api_url }
        let(:user_id) { deployer.id }
        let(:protected_environment) { group_protected_environment }
      end

      it_behaves_like 'requests to update approval rules' do
        let(:request_url) { api_url }
        let(:user_id) { deployer.id }
        let(:protected_environment) { group_protected_environment }
      end

      it 'updates the environment with shared group allowed to deploy' do
        put api_url, params: {
          deploy_access_levels: [
            {
              id: group_protected_environment.deploy_access_levels.first.id,
              group_id: shared_group.id,
              access_level: nil
            }
          ],
          required_approval_count: 1
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
        expect(json_response['deploy_access_levels'].length).to eq(1)
        expect(json_response['deploy_access_levels'].first['group_id']).to eq(shared_group.id)
        expect(json_response['required_approval_count']).to eq(1)
      end

      it 'updates the environment with group allowed to deploy with inheritance' do
        put api_url, params: {
          deploy_access_levels: [
            {
              id: group_protected_environment.deploy_access_levels.last.id,
              group_id: subgroup.id,
              access_level: nil,
              group_inheritance_type: ::ProtectedEnvironments::Authorizable::GROUP_INHERITANCE_TYPE[:ALL]
            }
          ],
          required_approval_count: 1
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
        expect(json_response['deploy_access_levels'].length).to eq(1)
        expect(json_response['deploy_access_levels'].last['group_id']).to eq(subgroup.id)
        expect(json_response['deploy_access_levels'].last['group_inheritance_type']).to eq(::ProtectedEnvironments::Authorizable::GROUP_INHERITANCE_TYPE[:ALL])
        expect(json_response['required_approval_count']).to eq(1)
      end

      it 'returns error with invalid deploy access level' do
        put api_url, params: { name: 'production', deploy_access_levels: [{ access_level: nil }] }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    it_behaves_like 'requests for non-maintainers' do
      let(:request) { put api_url, params: { name: 'production' } }
    end
  end

  describe 'DELETE /groups/:id/protected_environments/:environment' do
    let(:route) { "/groups/#{group.id}/protected_environments/production" }
    let(:request) { delete api(route, user) }

    it_behaves_like 'group-level request is disallowed for maintainer'

    context 'when authenticated as a owner' do
      before do
        group.add_owner(user)
      end

      it 'unprotects the environment' do
        expect do
          request
        end.to change { group.protected_environments.count }.by(-1)

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end
  end
end
