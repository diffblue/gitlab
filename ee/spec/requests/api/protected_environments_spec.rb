# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProtectedEnvironments do
  include AccessMatchersForRequest

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }

  let(:user) { create(:user) }
  let(:protected_environment_name) { 'production' }

  before do
    create(:protected_environment, :maintainers_can_deploy, :project_level, project: project, name: protected_environment_name, required_approval_count: 1)
    create(:protected_environment, :maintainers_can_deploy, :group_level, group: group, name: protected_environment_name, required_approval_count: 2)
  end

  shared_examples 'requests for non-maintainers' do
    it { expect { request }.to be_denied_for(:guest).of(project) }
    it { expect { request }.to be_denied_for(:developer).of(project) }
    it { expect { request }.to be_denied_for(:reporter).of(project) }
    it { expect { request }.to be_denied_for(:anonymous) }
  end

  describe "GET /projects/:id/protected_environments" do
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

  describe "GET /projects/:id/protected_environments/:environment" do
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

  describe "GET /groups/:id/protected_environments" do
    let(:route) { "/groups/#{group.id}/protected_environments" }
    let(:request) { get api(route, user), params: { per_page: 100 } }

    context 'when authenticated as a maintainer' do
      before do
        group.add_maintainer(user)
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

  describe "GET /groups/:id/protected_environments/:environment" do
    let(:requested_environment_name) { protected_environment_name }
    let(:route) { "/groups/#{group.id}/protected_environments/#{requested_environment_name}" }
    let(:request) { get api(route, user) }

    context 'when authenticated as a maintainer' do
      before do
        group.add_maintainer(user)
      end

      it 'returns the protected environment' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/protected_environment', dir: 'ee')
        expect(json_response['name']).to eq(protected_environment_name)
        expect(json_response['deploy_access_levels'][0]['access_level']).to eq(::Gitlab::Access::MAINTAINER)
        expect(json_response['required_approval_count']).to eq(2)
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

  describe 'POST /groups/:id/protected_environments/' do
    let(:api_url) { api("/groups/#{group.id}/protected_environments/", user) }

    context 'when authenticated as a maintainer' do
      before do
        group.add_maintainer(user)
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

    it_behaves_like 'requests for non-maintainers' do
      let(:request) { post api_url, params: { name: 'staging' } }
    end
  end

  describe 'DELETE /groups/:id/protected_environments/:environment' do
    let(:route) { "/groups/#{group.id}/protected_environments/production" }
    let(:request) { delete api(route, user) }

    context 'when authenticated as a maintainer' do
      before do
        group.add_maintainer(user)
      end

      it 'unprotects the environment' do
        expect do
          request
        end.to change { group.protected_environments.count }.by(-1)

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    it_behaves_like 'requests for non-maintainers'
  end
end
