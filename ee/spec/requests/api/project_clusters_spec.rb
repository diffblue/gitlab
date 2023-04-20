# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectClusters, feature_category: :deployment_management do
  include KubernetesHelpers

  let(:current_user) { create(:user) }
  let(:project) { create(:project, :repository) }

  shared_context 'kubernetes calls stubbed' do
    before do
      stub_kubeclient_discover(api_url)
      stub_kubeclient_get_namespace(api_url, namespace: namespace)
      stub_kubeclient_get_service_account(api_url, "#{namespace}-service-account", namespace: namespace)
      stub_kubeclient_put_service_account(api_url, "#{namespace}-service-account", namespace: namespace)

      stub_kubeclient_get_secret(
        api_url,
        metadata_name: "#{namespace}-token",
        token: Base64.encode64('sample-token'),
        namespace: namespace
      )

      stub_kubeclient_put_secret(api_url, "#{namespace}-token", namespace: namespace)
      stub_kubeclient_put_role_binding(api_url, "gitlab-#{namespace}", namespace: namespace)
    end
  end

  before do
    project.add_maintainer(current_user)
  end

  describe 'POST /projects/:id/clusters/user' do
    include_context 'kubernetes calls stubbed'

    let(:api_url) { 'https://kubernetes.example.com' }
    let(:namespace) { project.path }

    let(:platform_kubernetes_attributes) do
      {
        api_url: api_url,
        token: 'sample-token',
        namespace: namespace
      }
    end

    let(:cluster_params) do
      {
        name: 'test-cluster',
        environment_scope: 'production/*',
        platform_kubernetes_attributes: platform_kubernetes_attributes
      }
    end

    context 'when user sets specific environment scope' do
      it 'creates a cluster with that specific environment' do
        post api("/projects/#{project.id}/clusters/user", current_user), params: cluster_params

        expect(json_response['environment_scope']).to eq('production/*')
      end
    end

    context 'when does not set an specific environment scope' do
      let(:cluster_params) do
        {
          name: 'test-cluster',
          platform_kubernetes_attributes: platform_kubernetes_attributes
        }
      end

      it 'sets default environment' do
        post api("/projects/#{project.id}/clusters/user", current_user), params: cluster_params

        expect(json_response['environment_scope']).to eq('*')
      end
    end

    context 'when another cluster exists' do
      before do
        create(:cluster, :provided_by_gcp, :project,
               projects: [project])

        post api("/projects/#{project.id}/clusters/user", current_user), params: cluster_params
      end

      it 'responds with 201' do
        expect(response).to have_gitlab_http_status(:created)
      end

      it 'allows multiple clusters to be associated to project' do
        expect(project.reload.clusters.count).to eq(2)
      end
    end
  end

  describe 'PUT /projects/:id/clusters/:cluster_id' do
    include_context 'kubernetes calls stubbed'

    let(:api_url) { 'https://kubernetes.example.com' }
    let(:namespace) { project.path }

    let(:update_params) do
      {
        namespace: namespace,
        environment_scope: 'test/*'
      }
    end

    before do
      put api("/projects/#{project.id}/clusters/#{cluster.id}", current_user), params: update_params

      cluster.reload
    end

    context 'With a GCP cluster' do
      let(:cluster) do
        create(:cluster, :project, :provided_by_gcp,
               projects: [project])
      end

      it 'updates the environment scope' do
        expect(cluster.environment_scope).to eq('test/*')
      end
    end

    context 'With an user cluster' do
      let(:cluster) do
        create(:cluster, :project, :provided_by_user,
               projects: [project])
      end

      it 'updates the environment scope' do
        expect(cluster.environment_scope).to eq('test/*')
      end
    end
  end
end
